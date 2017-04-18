/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <6lowpan/uc6LoWPANPacketForwarding.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ieee154/ucIeee154FrameManipulation.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * The main module of a forwarder of IPv6
 * packets over a 6LoWPAN-compatible network
 * interface.
 *
 * @param max_num_staged_packets The maximal number
 *   of packets that can be enqueued for forwarding.
 * @param max_num_fragmented_packets The maximal number
 *   of packets that can be fragmented and transmitted
 *   concurrently.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANIPv6PacketForwarderMainPrv(
        uint8_t max_num_staged_packets,
        uint8_t max_num_fragmented_packets
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANIPv6PacketForwarder as Forwarder;
        interface Ieee154UnpackedDataFrameSender as FrameSender @exactlyonce();
    }
    uses
    {
        interface Bit as IsOnBit @exactlyonce();
        interface Bit as TxBit @exactlyonce();
        interface LoWPANFragmenter as Fragmenter @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as SubFrameSender @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as FrameAllocator @exactlyonce();
        interface Timer<TMilli, uint32_t> as TxTimer @exactlyonce();
        interface Ieee154LocalAddressProvider @exactlyonce();
        interface Ieee154FrameSequenceNumberGenerator @exactlyonce();
        interface LoWPANLinkTable @exactlyonce();
        interface ConfigValue<uint8_t> as MaxFrameRetransmissionAttempts @exactlyonce();
        interface ConfigValue<uint32_t> as BroadcastTxFailureRollbackDuration @exactlyonce();
        interface ConfigValue<uint32_t> as UnicastTxFailureRollbackDuration @exactlyonce();
        interface ConfigValue<uint32_t> as BroadcastTxSuccessRollbackDuration @exactlyonce();
        interface ConfigValue<uint32_t> as UnicastTxSuccessRollbackDuration @exactlyonce();
        interface Random;
        interface StatsIncrementer<uint8_t> as NumPacketsPassedForForwardingStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStartedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStoppedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByForwarderStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByForwarderStat;
    }
}
implementation
{

    // There are two queues. The staging queue, which is managed largely
    // by microc, contains all packets passed to the forwarded. The
    // fragmented packets array, in turn, contains packets that are
    // currently being fragmented. They are indexed by tokens returned
    // by the fragmenter.

    // No two packets destined to the same link-layer address can be
    // fragmented at the same time. This is crucial for broadcast packets
    // the frames of which must get consecutive BC0 sequence numbers.
    // It also possitively affects destination nodes, whose defragmenters
    // have potentially fewer packets to defragment concurrently.

    // This module also intercepts all frames from the fragmenter,
    // tags them with 15.4 sequence numbers, queues them, and depending
    // on the address, informs the link estimator about a presence/lack
    // of link-layer frame acks.

    // Upon start, the module allocates one frame to make sure that
    // it can always make progress.

    enum
    {
        MAX_NUM_STAGED_PACKETS = max_num_staged_packets,
        MAX_NUM_FRAGMENTED_PACKETS = max_num_fragmented_packets,
        MAX_FRAME_QUEUE_SIZE = MAX_NUM_FRAGMENTED_PACKETS,
    };


    enum
    {
        FRAGMENTED_PACKET_FLAG_BROADCAST = (1 << 6),
    };


    typedef struct lowpan_ipv6_packet_being_forwarded_s
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   stagingQueueElem;
        whip6_ieee154_dframe_info_t *                       freeFrame;
        whip6_ieee154_dframe_info_t *                       usedFrame;
        uint8_t                                             flags;
        uint8_t                                             numRetransmissionsRemaining;
    } lowpan_ipv6_packet_being_forwarded_t;
    typedef lowpan_ipv6_packet_being_forwarded_t lowpan_ipv6_packet_being_forwarded_t_xdata; typedef lowpan_ipv6_packet_being_forwarded_t_xdata whip6_lowpan_ipv6_packet_being_forwarded_t;



    whip6_lowpan_ipv6_packet_ready_for_forwarding_t         m_stagedPacketPool[MAX_NUM_STAGED_PACKETS];
    whip6_lowpan_ipv6_packet_ready_for_forwarding_queue_t   m_stagedPacketQueue;

    whip6_ieee154_dframe_info_t *                           m_freeFrame;

    whip6_lowpan_ipv6_packet_being_forwarded_t              m_fragmentedPackets[MAX_NUM_FRAGMENTED_PACKETS];

    whip6_lowpan_unpacked_frame_headers_t                   m_bcastLowpanHdrs;
    whip6_lowpan_header_bc0_seq_no_t                        m_bcastSeqNoGenerator;

    uint8_t                                                 m_frameQueueArray[MAX_FRAME_QUEUE_SIZE];
    uint8_t                                                 m_frameQueueFirstIdx;
    uint8_t                                                 m_frameQueueCount;



    static error_t stopForwardingNonfragmentedPacket(
            whip6_ipv6_packet_t * packet,
            error_t status
    );
    static void resetFragmentedPackets();
    static whip6_lowpan_ipv6_packet_being_forwarded_t * findFragmentedPacketWithSameLinkLayerAddrAsStagedPacket(
            whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem
    );
    static uint8_t findIndexOfFragmentedPacketWithGivenUsedFrame(
            whip6_ieee154_dframe_info_t * framePtr
    );
    static bool tryToStartForwardingStagedPacket(
            whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem
    );
    static bool prepareFrameForStagedPacket(
            whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem,
            whip6_ieee154_dframe_info_t * framePtr
    );
    static bool addFwdPacketIdxAsLastInFrameQueue(
            uint8_t fwdPacketIdx
    );
    static void removeFirstFwdPacketIndxFromFrameQueue();
    static void removeIthFwdPacketIndxFromFrameQueue(uint8_t i);
    static void restartTransmissionTimerAfterFailure(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr
    );
    static void restartTransmissionTimerAfterSuccess(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr
    );
    static void updateLinkTableAfterTransmittingUnicastFrameForForwardedPacket(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr,
            error_t status
    );
    static uint8_t findForwardedFrameWithGivenPacketIndex(
            uint8_t fwdPacketIdx
    );

    task void processStagedPacketsTask();
    task void processCompletedPacketsTask();
    task void processEnqueuedFramesTask();

//#define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

//#define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)


    command error_t SynchronousStarter.start()
    {
        uint16_t   tmp16;
        error_t    res;

        res = FAIL;
        local_dbg("[6LoWPAN::Forwarder] Starting.\r\n");
        if (call IsOnBit.isSet())
        {
            local_dbg("[6LoWPAN::Forwarder] The forwarder is already running.\r\n");
            res = EALREADY;
            goto FAILURE_ROLLBACK_0;
        }
        whip6_lowpanPacketForwardingStagingQueueInit(
                &m_stagedPacketQueue,
                &(m_stagedPacketPool[0]),
                MAX_NUM_STAGED_PACKETS
        );
        m_freeFrame = call FrameAllocator.allocFrame();
        if (m_freeFrame == NULL)
        {
            local_dbg("[6LoWPAN::Forwarder] No memory to allocate a frame.\r\n");
            res = ENOMEM;
            goto FAILURE_ROLLBACK_0;
        }
        call NumFramesAllocatedByForwarderStat.increment(1);
        resetFragmentedPackets();
        tmp16 = call Random.rand16();
        m_bcastSeqNoGenerator = (whip6_lowpan_header_bc0_seq_no_t)(tmp16 >> 8);
        m_frameQueueFirstIdx = 0;
        m_frameQueueCount = 0;
        call TxBit.clear();
        call IsOnBit.set();
        return SUCCESS;

    // FAILURE_ROLLBACK_1:
    //     call FrameAllocator.freeFrame(m_freeFrame);
    FAILURE_ROLLBACK_0:
        return res;
    }



    static void resetFragmentedPackets()
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fragPkt;
        uint8_t                                        i;

        fragPkt = &(m_fragmentedPackets[0]);
        for (i = MAX_NUM_FRAGMENTED_PACKETS; i > 0; --i)
        {
            fragPkt->stagingQueueElem = NULL;
            ++fragPkt;
        }
    }



    command error_t Forwarder.startForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr
    )
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem;

        local_dbg("[6LoWPAN::Forwarder] Trying to enqueue packet %lu "
            "for forwarding to address %lu.\r\n", (long unsigned)packet,
            (long unsigned)llAddr);
        call NumPacketsPassedForForwardingStat.increment(1);
        if (call IsOnBit.isClear())
        {
            local_dbg("[6LoWPAN::Forwarder] The forwarder is off.\r\n");
            return EOFF;
        }
        stagingQueueElem =
                whip6_lowpanPacketForwardingStagingQueueEnqueuePacket(
                        &m_stagedPacketQueue,
                        packet,
                        llAddr
                );
        if (stagingQueueElem == NULL)
        {
            local_dbg("[6LoWPAN::Forwarder] No memory to enqueue packet %lu.\r\n",
                (long unsigned)packet);
            return ENOMEM;
        }
        local_dbg("[6LoWPAN::Forwarder] Packet %lu has been enqueued "
            "for forwarding to address %lu.\r\n", (long unsigned)packet,
            (long unsigned)llAddr);
        post processStagedPacketsTask();
        call NumPacketsStartedBeingForwardedStat.increment(1);
        return SUCCESS;
    }



    task void processStagedPacketsTask()
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   currStagingQueueElem;
        whip6_lowpan_ipv6_packet_being_forwarded_t *        fwdPacket;

        local_dbg("[6LoWPAN::Forwarder] Starting processing staged packets.\r\n");
        currStagingQueueElem =
                whip6_lowpanPacketForwardingStagingQueueGetFirstStagedPacket(
                        &m_stagedPacketQueue
                );
        while (currStagingQueueElem != NULL)
        {
            fwdPacket =
                    findFragmentedPacketWithSameLinkLayerAddrAsStagedPacket(
                            currStagingQueueElem
                    );
            if (fwdPacket == NULL)
            {
                bool forwardingSuccessful;

                local_dbg("[6LoWPAN::Forwarder] Trying to start forwarding "
                    "staged packet %lu.\r\n", (long unsigned)
                    whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                        currStagingQueueElem));
                forwardingSuccessful =
                        tryToStartForwardingStagedPacket(currStagingQueueElem);
                if (forwardingSuccessful)
                {
                    post processStagedPacketsTask();
                }
                local_dbg("[6LoWPAN::Forwarder] %s finished processing staged packets.\r\n",
                    forwardingSuccessful ? "Temporarily" : "Completely");
                return;
            }
            currStagingQueueElem =
                    whip6_lowpanPacketForwardingStagingQueueGetNextStagedPacket(
                            &m_stagedPacketQueue,
                            currStagingQueueElem
                    );
        }
        local_dbg("[6LoWPAN::Forwarder] No staged packets to process. "
            "Completely finished processing staged packets.\r\n");
    }



    static whip6_lowpan_ipv6_packet_being_forwarded_t * findFragmentedPacketWithSameLinkLayerAddrAsStagedPacket(
            whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem
    )
    {
        whip6_ieee154_addr_t const *                   soughtAddr;
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fragPkt;
        uint8_t                                        i;

        soughtAddr =
                whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                        stagingQueueElem
                );
        fragPkt = &(m_fragmentedPackets[0]);
        for (i = MAX_NUM_FRAGMENTED_PACKETS; i > 0; --i)
        {
            if (fragPkt->stagingQueueElem == stagingQueueElem)
            {
                return fragPkt;
            }
            else if (fragPkt->stagingQueueElem != NULL)
            {
                whip6_ieee154_addr_t const *   currAddr;
                currAddr =
                        whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                                fragPkt->stagingQueueElem
                        );
                if (whip6_ieee154AddrAnyCmp(soughtAddr, currAddr) == 0)
                {
                    return fragPkt;
                }
            }
            ++fragPkt;
        }
        return NULL;
    }



    static bool tryToStartForwardingStagedPacket(
            whip6_lowpan_ipv6_packet_ready_for_forwarding_t * stagingQueueElem
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fwdPacket;
        uint8_t                                        fragToken;
        bool                                           bcastAddr;

        if (m_freeFrame == NULL)
        {
            m_freeFrame = call FrameAllocator.allocFrame();
            if (m_freeFrame == NULL)
            {
                local_dbg("[6LoWPAN::Forwarder] No free frames.\r\n");
                return FALSE;
            }
            call NumFramesAllocatedByForwarderStat.increment(1);
        }
        bcastAddr =
                whip6_ieee154AddrAnyIsBroadcast(
                        whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                                stagingQueueElem
                        )
                );
        fragToken =
                call Fragmenter.startFragmentingIpv6Packet(
                        whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                                stagingQueueElem
                        ),
                        bcastAddr ? &m_bcastLowpanHdrs : NULL
                );
        if (fragToken == 0)
        {
            local_dbg("[6LoWPAN::Forwarder] Unable to start fragmentation.\r\n");
            return FALSE;
        }
        local_assert(fragToken <= MAX_NUM_FRAGMENTED_PACKETS);
        fwdPacket = &(m_fragmentedPackets[fragToken - 1]);
        local_assert(fwdPacket->stagingQueueElem == NULL);
        fwdPacket->stagingQueueElem = stagingQueueElem;
        fwdPacket->freeFrame = m_freeFrame;
        m_freeFrame = NULL;
        fwdPacket->usedFrame = NULL;
        fwdPacket->flags = bcastAddr ? FRAGMENTED_PACKET_FLAG_BROADCAST : 0;
        // NOTICE iwanicki 2013-09-25:
        // This is not really necessary, because the number of
        // retransmissions is set for each frame. However, let's
        // leave it here for a while.
        fwdPacket->numRetransmissionsRemaining = 0;
        local_dbg("[6LoWPAN::Forwarder] Successfully initiated fragmentation "
            "of the packet.\r\n");
        return TRUE;
    }



    event whip6_ieee154_dframe_info_t * Fragmenter.frameForFragmentedPacketRequested(
            uint8_t token
    )
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   stagingQueueElem;
        whip6_lowpan_ipv6_packet_being_forwarded_t *        fragPkt;
        whip6_ieee154_dframe_info_t *                       framePtr;

        local_assert(token > 0);
        local_assert(token <= MAX_NUM_FRAGMENTED_PACKETS);
        --token;
        fragPkt = &(m_fragmentedPackets[token]);
        stagingQueueElem = fragPkt->stagingQueueElem;
        local_assert(stagingQueueElem != NULL);
        local_dbg("[6LoWPAN::Forwarder] Requested a new frame for packet %lu.\r\n",
            (long unsigned)whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                stagingQueueElem));
        framePtr = fragPkt->freeFrame;
        if (framePtr == NULL)
        {
            // NOTICE iwanicki 2013-09-25:
            // This may happen because the fragmenter may actually
            // request multiple packets from us. We guarantee to
            // always have at least one frame available.
            local_dbg("[6LoWPAN::Forwarder] No frame available.\r\n");
            local_assert(fragPkt->usedFrame != NULL);
            return NULL;
        }
        local_assert(fragPkt->usedFrame == NULL);
        fragPkt->freeFrame = NULL;
        if (whip6_ieee154DFrameInfoReinitializeFrameForAddresses(
                    framePtr,
                    whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                        stagingQueueElem
                    ),
                    call Ieee154LocalAddressProvider.getAddrPtr(),
                    call Ieee154LocalAddressProvider.getPanIdPtr(),
                    NULL
                ) != WHIP6_NO_ERROR)
        {
            local_dbg("[6LoWPAN::Forwarder] The available frame, %lu, cannot "
                "be prepared.\r\n", (long unsigned)framePtr);
            // NOTICE iwanicki 2013-09-25:
            // We know that the fragmenter will fail anyway,
            // so in theory we could free the frame here.
            // However, let's not do this, and instead,
            // let's just restore the free frame.
            fragPkt->freeFrame = framePtr;
            return NULL;
        }
        whip6_ieee154DFrameSetSeqNo(
                framePtr,
                call Ieee154FrameSequenceNumberGenerator.generateSeqNo()
        );
        fragPkt->usedFrame = framePtr;
        if ((fragPkt->flags & FRAGMENTED_PACKET_FLAG_BROADCAST) != 0)
        {
            local_dbg("[6LoWPAN::Forwarder] Setting the 6LoWPAN BC0 sequence "
                "number for a broadcast frame to %lu.\r\n",
                (long unsigned)m_bcastSeqNoGenerator);
            whip6_lowpanFrameHeadersNew(&m_bcastLowpanHdrs);
            whip6_lowpanFrameHeadersAddBc0Header(&m_bcastLowpanHdrs, m_bcastSeqNoGenerator);
            fragPkt->numRetransmissionsRemaining = 0;
        }
        else
        {
            fragPkt->numRetransmissionsRemaining = call MaxFrameRetransmissionAttempts.get();
        }
        local_dbg("[6LoWPAN::Forwarder] Providing frame %lu.\r\n",
            (long unsigned)framePtr);
        return framePtr;
    }



    command error_t FrameSender.startSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        uint8_t   fwdPacketIdx;

        local_dbg("[6LoWPAN::Forwarder] Trying to enqueue frame %lu for sending.\r\n",
            (long unsigned)framePtr);
        fwdPacketIdx = findIndexOfFragmentedPacketWithGivenUsedFrame(framePtr);
        local_assert(fwdPacketIdx < MAX_NUM_FRAGMENTED_PACKETS);
        if (! addFwdPacketIdxAsLastInFrameQueue(fwdPacketIdx))
        {
            local_dbg("[6LoWPAN::Forwarder] No queue space for the frame.\r\n");
            return ENOMEM;
        }
        local_dbg("[6LoWPAN::Forwarder] The frame has been enqueued for sending.\r\n");
        if (! call TxTimer.isRunning() && call TxBit.isClear())
        {
            local_dbg("[6LoWPAN::Forwarder] Starting the transmission timer.\r\n");
            call TxTimer.startWithTimeoutFromNow(0);
        }
        return SUCCESS;
    }



    static uint8_t findIndexOfFragmentedPacketWithGivenUsedFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fwdPacketPtr;
        uint8_t                                        fwdPacketIdx;

        fwdPacketPtr = &(m_fragmentedPackets[0]);
        for (fwdPacketIdx = 0; fwdPacketIdx < MAX_NUM_FRAGMENTED_PACKETS; ++fwdPacketIdx)
        {
            if (fwdPacketPtr->stagingQueueElem != NULL)
            {
                if (fwdPacketPtr->usedFrame == framePtr)
                {
                    return fwdPacketIdx;
                }
            }
            ++fwdPacketPtr;
        }
        return MAX_NUM_FRAGMENTED_PACKETS;
    }



    static bool addFwdPacketIdxAsLastInFrameQueue(
            uint8_t fwdPacketIdx
    )
    {
        uint8_t   frameQueueIdx;

        if (m_frameQueueCount >= MAX_FRAME_QUEUE_SIZE)
        {
            return FALSE;
        }
        frameQueueIdx =
                (m_frameQueueFirstIdx + m_frameQueueCount) % MAX_FRAME_QUEUE_SIZE;
        m_frameQueueArray[frameQueueIdx] = fwdPacketIdx;
        ++m_frameQueueCount;
        return TRUE;
    }



    event inline void TxTimer.fired()
    {
        local_dbg("[6LoWPAN::Forwarder] The forwarding timer fired.\r\n");
        post processEnqueuedFramesTask();
    }



    task void processEnqueuedFramesTask()
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fwdPacketPtr;
        whip6_ieee154_dframe_info_t *                  framePtr;
        uint8_t                                        fwdPacketIdx;
        error_t                                        err;

        local_dbg("[6LoWPAN::Forwarder] Trying to transmit the first frame "
            "from the forwarding queue.\r\n");
        if (call TxBit.isSet() || m_frameQueueCount == 0)
        {
            local_dbg("[6LoWPAN::Forwarder] No transmission can be performed "
                "at this moment.\r\n");
            return;
        }
        local_assert(m_frameQueueFirstIdx < MAX_FRAME_QUEUE_SIZE);
        fwdPacketIdx = m_frameQueueArray[m_frameQueueFirstIdx];
        local_assert(fwdPacketIdx < MAX_NUM_FRAGMENTED_PACKETS);
        fwdPacketPtr = &(m_fragmentedPackets[fwdPacketIdx]);
        local_assert(fwdPacketPtr->stagingQueueElem != NULL);
        framePtr = fwdPacketPtr->usedFrame;
        local_assert(framePtr != NULL);
        err = call SubFrameSender.startSendingFrame(framePtr);
        if (err != SUCCESS)
        {
            removeFirstFwdPacketIndxFromFrameQueue();
            restartTransmissionTimerAfterFailure(fwdPacketPtr);
            if (fwdPacketPtr->numRetransmissionsRemaining > 0)
            {
                --fwdPacketPtr->numRetransmissionsRemaining;
                addFwdPacketIdxAsLastInFrameQueue(fwdPacketIdx);
            }
            else
            {
                signal FrameSender.frameSendingFinished(framePtr, err);
            }
            return;
        }
        call TxBit.set();
        local_dbg("[6LoWPAN::Forwarder] Successfully initiated the forwarding "
            "of frame %lu.\r\n", (long unsigned)framePtr);
    }



    static void removeFirstFwdPacketIndxFromFrameQueue()
    {
        local_assert(m_frameQueueCount > 0);
        ++m_frameQueueFirstIdx;
        m_frameQueueFirstIdx %= MAX_FRAME_QUEUE_SIZE;
        --m_frameQueueCount;
    }



    static inline void restartTransmissionTimerAfterFailure(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr
    )
    {
        call TxTimer.startWithTimeoutFromNow(
                (fwdPacketPtr->flags & FRAGMENTED_PACKET_FLAG_BROADCAST) != 0 ?
                        call BroadcastTxFailureRollbackDuration.get() :
                        call UnicastTxFailureRollbackDuration.get()
        );
    }



    static inline void restartTransmissionTimerAfterSuccess(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr
    )
    {
        call TxTimer.startWithTimeoutFromNow(
                (fwdPacketPtr->flags & FRAGMENTED_PACKET_FLAG_BROADCAST) != 0 ?
                        call BroadcastTxSuccessRollbackDuration.get() :
                        call UnicastTxSuccessRollbackDuration.get()
        );
    }



    command error_t FrameSender.stopSendingFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fwdPacketPtr;
        uint8_t                                        fwdPacketIdx;
        uint8_t                                        frameQueueIdx;

        local_dbg("[6LoWPAN::Forwarder] Trying to stop transmitting "
            "frame %lu from the forwarding queue.\r\n", (long unsigned)framePtr);
        fwdPacketIdx = findIndexOfFragmentedPacketWithGivenUsedFrame(framePtr);
        if (fwdPacketIdx == MAX_NUM_FRAGMENTED_PACKETS)
        {
            local_dbg("[6LoWPAN::Forwarder] No packet found for the frame.\r\n");
            return EINVAL;
        }
        frameQueueIdx = findForwardedFrameWithGivenPacketIndex(fwdPacketIdx);
        if (frameQueueIdx == MAX_FRAME_QUEUE_SIZE)
        {
            local_dbg("[6LoWPAN::Forwarder] No queue entry found for the frame.\r\n");
            return EINVAL;
        }
        if (frameQueueIdx == 0)
        {
            error_t status;
            status = call SubFrameSender.stopSendingFrame(framePtr);
            if (status != SUCCESS)
            {
                local_dbg("[6LoWPAN::Forwarder] Failed to stop the transmission "
                    "of frame %lu at a lower layer.\r\n", (long unsigned)framePtr);
                return status;
            }
        }
        removeIthFwdPacketIndxFromFrameQueue(frameQueueIdx);
        local_dbg("[6LoWPAN::Forwarder] Successfully stopped the transmission "
            "of frame %lu.\r\n", (long unsigned)framePtr);
        return SUCCESS;
    }



    static uint8_t findForwardedFrameWithGivenPacketIndex(
            uint8_t fwdPacketIdx
    )
    {
        uint8_t   i;
        uint8_t   n;

        for (i = m_frameQueueFirstIdx, n = m_frameQueueCount; n > 0; --n)
        {
            if (m_frameQueueArray[i] == fwdPacketIdx)
            {
                return m_frameQueueCount - n;
            }
            i = (i + 1) % MAX_FRAME_QUEUE_SIZE;
        }
        return MAX_FRAME_QUEUE_SIZE;
    }



    static void removeIthFwdPacketIndxFromFrameQueue(uint8_t i)
    {
        uint8_t   currIdx;
        uint8_t   prevIdx;
        uint8_t   cnt;

        prevIdx = (m_frameQueueFirstIdx + i) % MAX_FRAME_QUEUE_SIZE;
        for (cnt = m_frameQueueCount - i - 1; cnt > 0; --cnt)
        {
            currIdx = (prevIdx + 1) % MAX_FRAME_QUEUE_SIZE;
            m_frameQueueArray[prevIdx] = m_frameQueueArray[currIdx];
            prevIdx = currIdx;
        }
        --m_frameQueueCount;
        if (i == 0)
        {
            ++m_frameQueueFirstIdx;
            m_frameQueueFirstIdx %= MAX_FRAME_QUEUE_SIZE;
        }
    }



    event void SubFrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fwdPacketPtr;
        uint8_t                                        fwdPacketIdx;

        local_assert(call TxBit.isSet());
        local_assert(m_frameQueueCount > 0);
        local_assert(m_frameQueueFirstIdx < MAX_FRAME_QUEUE_SIZE);
        fwdPacketIdx = m_frameQueueArray[m_frameQueueFirstIdx];
        local_assert(fwdPacketIdx < MAX_NUM_FRAGMENTED_PACKETS);
        fwdPacketPtr = &(m_fragmentedPackets[fwdPacketIdx]);
        local_assert(fwdPacketPtr->usedFrame == framePtr);
        local_dbg("[6LoWPAN::Forwarder] Learning that the forwarding of "
            "frame %lu has finished with status %u.\r\n",
            (long unsigned)framePtr, (unsigned)status);
        call TxBit.clear();
        if ((fwdPacketPtr->flags & FRAGMENTED_PACKET_FLAG_BROADCAST) != 0)
        {
            ++m_bcastSeqNoGenerator;
        }
        else
        {
            updateLinkTableAfterTransmittingUnicastFrameForForwardedPacket(
                    fwdPacketPtr,
                    status
            );
        }
        removeFirstFwdPacketIndxFromFrameQueue();
        if (status == SUCCESS)
        {
            restartTransmissionTimerAfterSuccess(fwdPacketPtr);
            local_dbg("[6LoWPAN::Forwarder] Signaling the completion of "
                "forwarding of frame %lu.\r\n", (long unsigned)framePtr);
            signal FrameSender.frameSendingFinished(framePtr, SUCCESS);
        }
        else
        {
            restartTransmissionTimerAfterFailure(fwdPacketPtr);
            if (fwdPacketPtr->numRetransmissionsRemaining == 0 ||
                    (fwdPacketPtr->flags & FRAGMENTED_PACKET_FLAG_BROADCAST) != 0)
            {
                local_dbg("[6LoWPAN::Forwarder] Signaling the completion of "
                    "forwarding of frame %lu.\r\n", (long unsigned)framePtr);
                signal FrameSender.frameSendingFinished(framePtr, status);
            }
            else
            {
                --fwdPacketPtr->numRetransmissionsRemaining;
                addFwdPacketIdxAsLastInFrameQueue(fwdPacketIdx);
            }
        }
    }



    static void updateLinkTableAfterTransmittingUnicastFrameForForwardedPacket(
            whip6_lowpan_ipv6_packet_being_forwarded_t * fwdPacketPtr,
            error_t status
    )
    {
        lowpan_link_index_t   linkIdx;

        linkIdx =
                call LoWPANLinkTable.findExistingLink(
                        whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                                fwdPacketPtr->stagingQueueElem
                        )
                );
        if (linkIdx == WHIP6_6LOWPAN_INVALID_LINK_IDX)
        {
            local_dbg("[6LoWPAN::Forwarder] No link found for which the ACK "
                "status could be reported.\r\n");
            return;
        }
        if (status == SUCCESS)
        {
            local_dbg("[6LoWPAN::Forwarder] Reporting ACK for "
                "the link with index %u.\r\n", (unsigned)linkIdx);
            call LoWPANLinkTable.reportAcknowledgedUnicastForLink(linkIdx);
        }
        else if (status == ENOACK)
        {
            local_dbg("[6LoWPAN::Forwarder] Reporting NOACK for "
                "the link with index %u.\r\n", (unsigned)linkIdx);
            call LoWPANLinkTable.reportUnacknowledgedUnicastForLink(linkIdx);
        }
    }



    event void Fragmenter.frameForFragmentedPacketReleased(
            uint8_t token,
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fragPkt;

        local_assert(token > 0);
        local_assert(token <= MAX_NUM_FRAGMENTED_PACKETS);
        --token;
        fragPkt = &(m_fragmentedPackets[token]);
        local_assert(fragPkt->stagingQueueElem != NULL);
        local_assert(fragPkt->usedFrame == framePtr);
        local_dbg("[6LoWPAN::Forwarder] Releasing frame %lu assigned to packet %lu.\r\n",
            (long unsigned)framePtr, (long unsigned)
            whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                fragPkt->stagingQueueElem));
        fragPkt->usedFrame = NULL;
        if (fragPkt->freeFrame != NULL)
        {
            local_dbg("[6LoWPAN::Forwarder] Freeing the frame.\r\n");
            call NumFramesFreedByForwarderStat.increment(1);
            call FrameAllocator.freeFrame(framePtr);
        }
        else
        {
            local_dbg("[6LoWPAN::Forwarder] Keeping the frame.\r\n");
            fragPkt->freeFrame = framePtr;
        }
    }



    event void Fragmenter.fragmentingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            uint8_t token,
            error_t status
    )
    {
        whip6_lowpan_ipv6_packet_being_forwarded_t *   fragPkt;
        whip6_ieee154_dframe_info_t *                  framePtr;

        local_dbg("[6LoWPAN::Forwarder] Finished fragmenting packet %lu.\r\n",
            (long unsigned)packet);
        local_assert(token > 0);
        local_assert(token <= MAX_NUM_FRAGMENTED_PACKETS);
        --token;
        fragPkt = &(m_fragmentedPackets[token]);
        local_assert(fragPkt->stagingQueueElem != NULL);
        local_assert(whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(fragPkt->stagingQueueElem) == packet);
        local_assert(fragPkt->usedFrame == NULL);
        framePtr = fragPkt->freeFrame;
        if (framePtr != NULL)
        {
            if (m_freeFrame == NULL)
            {
                local_dbg("[6LoWPAN::Forwarder] Preserving frame %lu as free.\r\n",
                    (long unsigned)framePtr);
                m_freeFrame = framePtr;
            }
            else
            {
                local_dbg("[6LoWPAN::Forwarder] Freeing frame %lu.\r\n",
                    (long unsigned)framePtr);
                call NumFramesFreedByForwarderStat.increment(1);
                call FrameAllocator.freeFrame(framePtr);
            }
        }
        fragPkt->freeFrame = NULL;
        fragPkt->stagingQueueElem = NULL;
        status = stopForwardingNonfragmentedPacket(packet, status);
        local_assert(status == SUCCESS);
        (void)status;
    }




    command error_t Forwarder.stopForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet
    )
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   stagingQueueElem;
        whip6_lowpan_ipv6_packet_being_forwarded_t *        fragPacketPtr;
        uint8_t                                             fragPacketIdx;
        error_t                                             status;

        local_dbg("[6LoWPAN::Forwarder] Trying to stop forwarding packet "
            "%lu.\r\n", (long unsigned)packet);
        fragPacketPtr = &(m_fragmentedPackets[0]);
        for (fragPacketIdx = 0; fragPacketIdx < MAX_NUM_FRAGMENTED_PACKETS; ++fragPacketIdx)
        {
            stagingQueueElem = fragPacketPtr->stagingQueueElem;
            if (stagingQueueElem != NULL)
            {
                if (whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                            stagingQueueElem
                    ) == packet)
                {
                    local_dbg("[6LoWPAN::Forwarder] The packet is being "
                        "fragmented. Trying to stop the fragmentation.\r\n");
                    status =
                            call Fragmenter.stopFragmentingIpv6Packet(
                                    fragPacketIdx + 1
                            );
                    if (status == SUCCESS)
                    {
                        call NumPacketsStoppedBeingForwardedStat.increment(1);
                    }
                    return status;
                }
            }
            ++fragPacketPtr;
        }
        local_dbg("[6LoWPAN::Forwarder] The packet is not being fragmented.\r\n");
        status = stopForwardingNonfragmentedPacket(packet, ECANCEL);
        if (status != SUCCESS)
        {
            call NumPacketsStoppedBeingForwardedStat.increment(1);
        }
        return status;
    }



    static error_t stopForwardingNonfragmentedPacket(
            whip6_ipv6_packet_t * packet,
            error_t status
    )
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   prevStagingQueueElem;
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   currStagingQueueElem;

        local_dbg("[6LoWPAN::Forwarder] Searching for packet %lu in the "
            "processed packets queue.\r\n", (long unsigned)packet);
        currStagingQueueElem =
                whip6_lowpanPacketForwardingStagingQueueFindStagedPacket(
                        &m_stagedPacketQueue,
                        packet,
                        &prevStagingQueueElem
                );
        if (currStagingQueueElem != NULL)
        {
            local_dbg("[6LoWPAN::Forwarder] Found packet %lu in the "
                "processed packets queue. Marking the packet as completed "
                "with status %u.\r\n", (long unsigned)packet, (unsigned)status);
            currStagingQueueElem->status = status;
            whip6_lowpanPacketForwardingStagingQueueMarkPacketAsCompleted(
                    &m_stagedPacketQueue,
                    prevStagingQueueElem,
                    currStagingQueueElem
            );
            post processCompletedPacketsTask();
            return SUCCESS;
        }
        local_dbg("[6LoWPAN::Forwarder] Packet %lu is not present in the "
            "processed packets queue. Searching for it in the completed "
            "packets queue.\r\n", (long unsigned)packet);
        currStagingQueueElem =
                whip6_lowpanPacketForwardingStagingQueueFindCompletedPacket(
                        &m_stagedPacketQueue,
                        packet,
                        NULL
                );
        return currStagingQueueElem != NULL ? EALREADY : EINVAL;
    }



    task void processCompletedPacketsTask()
    {
        whip6_lowpan_ipv6_packet_ready_for_forwarding_t *   firstStagingQueueElem;
        
        local_dbg("[6LoWPAN::Forwarder] Starting processing completed packets.\r\n");
        firstStagingQueueElem =
                whip6_lowpanPacketForwardingStagingQueueGetFirstCompletedPacket(
                        &m_stagedPacketQueue
                );
        if (firstStagingQueueElem == NULL)
        {
            local_dbg("[6LoWPAN::Forwarder] Completely finished processing "
                "completed packets.\r\n");
            return;
        }
        post processCompletedPacketsTask();
        local_dbg("[6LoWPAN::Forwarder] Finished processing packet %lu.\r\n",
            (long unsigned)whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                firstStagingQueueElem));
        call NumPacketsFinishedBeingForwardedStat.increment(1);
        signal Forwarder.forwardingIpv6PacketFinished(
                whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
                        firstStagingQueueElem
                ),
                whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
                        firstStagingQueueElem
                ),
                whip6_lowpanPacketForwardingStagingQueueGetStatusForQueueElement(
                        firstStagingQueueElem
                )
        );
        whip6_lowpanPacketForwardingStagingQueueRemoveFirstCompletedPacket(
                &m_stagedPacketQueue
        );
        local_dbg("[6LoWPAN::Forwarder] Temporarily finished processing "
            "completed packets.\r\n");
    }



    default command inline void NumPacketsPassedForForwardingStat.increment(uint8_t val)
    {
    }



    default command inline void NumPacketsStartedBeingForwardedStat.increment(uint8_t val)
    {
    }



    default command inline void NumPacketsStoppedBeingForwardedStat.increment(uint8_t val)
    {
    }



    default command inline void NumPacketsFinishedBeingForwardedStat.increment(uint8_t val)
    {
    }




    default command inline void NumFramesAllocatedByForwarderStat.increment(uint8_t val)
    {
    }



    default command inline void NumFramesFreedByForwarderStat.increment(uint8_t val)
    {
    }

#undef local_dbg
#undef local_assert

}
