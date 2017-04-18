/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"
#include "TimerTypes.h"
#include <6lowpan/uc6LoWPANDefragmentation.h>
#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>



/**
 * The main module of a defragmenter of 6LoWPAN frames.
 *
 * @param defrag_packet_pool_size The maximal number of
 *   packets that can be concurrently defragmented. Zero
 *   means that all packets must fit in a single frame.
 * @param frag_spec_pool_size The maximal number of
 *   packet fragments specifications that allow for
 *   defragmenting packets from pieces that come out
 *   of order. Zero means that no out of order
 *   defragmentation is possible.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANDefragmenterMainPrv(
    uint8_t defrag_packet_pool_size,
    uint8_t frag_spec_pool_size
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANDefragmenter as Defragmenter;
    }
    uses
    {
        interface Bit as IsOnBit @exactlyonce();
        interface Bit as TimeoutPendingBit @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator @exactlyonce(); 
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameMetadata;
        interface LoWPANLinkTable;
        interface Queue<whip6_ieee154_dframe_info_t *, uint8_t> as Ieee154FrameQueue @exactlyonce();
        interface Timer<TMilli, uint32_t> as ReassemblyTimeoutTimer @exactlyonce();
        /** By default 65536 ms */
        interface ConfigValue<uint32_t> as ReassemblyTimeoutInMillis @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingDefragmentedStat;
        interface StatsIncrementer<uint8_t> as NumFramesReceivedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByDefragmenterStat;
    }
}
implementation
{
    enum
    {
        DEFRAG_PACKET_POOL_SIZE = defrag_packet_pool_size,
        FRAG_SPEC_POOL_SIZE = frag_spec_pool_size,
        FRAG_SPEC_ARRAY_SIZE_FOR_STUPID_COMPILERS =
            FRAG_SPEC_POOL_SIZE > 0 ? FRAG_SPEC_POOL_SIZE : 1,
    };

    enum
    {
        DONE_NOTHING = 0,
        DONE_UNPACK_6LOWPAN_HDRS,
        DONE_LOCK_IPV6_PACKET,
        DONE_DEFRAGMENTING_IPV6_PACKET,
    };

    whip6_lowpan_defrag_global_state_t      m_state;
    whip6_lowpan_defrag_packet_state_t      m_dfragPacketPool[DEFRAG_PACKET_POOL_SIZE];
    whip6_lowpan_defrag_frag_spec_t         m_fragSpecPool[FRAG_SPEC_ARRAY_SIZE_FOR_STUPID_COMPILERS];
    whip6_lowpan_defrag_packet_state_t *    m_processedPacket = NULL;
    whip6_ipv6_packet_t *                   m_readyPacket = NULL;
    whip6_lowpan_unpacked_frame_headers_t   m_unpackedHeaders;
    uint8_t                                 m_doneUntilNow;
    whip6_ieee154_addr_t                    m_ieee154AddrScratchpad;


    task void processReceivedFrameTask();
    error_t startReceivingFrame(whip6_ieee154_dframe_info_t * framePtr);
    void startProcessingFrameIfNecessary(whip6_ieee154_dframe_info_t * framePtr);
    void stopProcessingFrameAndStartReceivingNewOne();
    bool unpack6LoWPANHeaders(whip6_ieee154_dframe_info_t * framePtr);
    void updateLinkTableFromBC0Header(bool allowReplacement);
    bool startDefragmentationIfRequired(whip6_ieee154_dframe_info_t * framePtr);
    bool mergeFragmentToPacket(whip6_ieee154_dframe_info_t * framePtr);
    bool deliverDefragmentedPacket();
    void tryToHandlePeriodicTimeout();

// #define local_dbg(...) printf(__VA_ARGS__)
// #define local_dbg(...) usb_printf(__VA_ARGS__)
 #define local_dbg(...)

    command error_t SynchronousStarter.start()
    {
        error_t err = FAIL;
        local_dbg("[6LoWPAN::Defragmenter] Starting the IPv6 packet defragmenter.\r\n");
        if (! call Ieee154FrameQueue.isEmpty())
        {
            local_dbg("[6LoWPAN::Defragmenter] The queue of the IPv6 packet "
                "defragmenter is not empty.\r\n");
            err = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        if (call IsOnBit.isSet())
        {
            local_dbg("[6LoWPAN::Defragmenter] The IPv6 packet defragmenter "
                "is already running.\r\n");
            err = EALREADY;
            goto FAILURE_ROLLBACK_0;
        }
        call IsOnBit.set();
        whip6_lowpanDefragmenterInit(
                &m_state,
                DEFRAG_PACKET_POOL_SIZE > 0 ? m_dfragPacketPool : NULL,
                FRAG_SPEC_POOL_SIZE > 0 ? m_fragSpecPool : NULL,
                DEFRAG_PACKET_POOL_SIZE,
                FRAG_SPEC_POOL_SIZE
        );
        err = startReceivingFrame(NULL);
        if (err != SUCCESS)
        {
            local_dbg("[6LoWPAN::Defragmenter] Failed to initiate receiving "
                "802.15.4 frames.\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        call ReassemblyTimeoutTimer.startWithTimeoutFromNow(
                (call ReassemblyTimeoutInMillis.get()) >> 1
        );
        local_dbg("[6LoWPAN::Defragmenter] Started the IPv6 packet defragmenter.\r\n");
        return SUCCESS;
    
    FAILURE_ROLLBACK_1:
        call IsOnBit.clear();
    FAILURE_ROLLBACK_0:
        return err;
    }



    error_t startReceivingFrame(whip6_ieee154_dframe_info_t * framePtr)
    {
        error_t err = FAIL;

        if (call Ieee154FrameQueue.isFull())
        {
            err = ENOMEM;
            goto FAILURE_ROLLBACK_0;
        }
        if (framePtr == NULL)
        {
            framePtr = call Ieee154FrameAllocator.allocFrame();
            if (framePtr == NULL)
            {
                err = ENOMEM;
                goto FAILURE_ROLLBACK_0;
            }
            call NumFramesAllocatedByDefragmenterStat.increment(1);
        }
        err = call Ieee154FrameReceiver.startReceivingFrame(framePtr);
        if (err == SUCCESS)
        {
            return SUCCESS;
        }
        else if (err == EALREADY)
        {
            err = SUCCESS;
        }

    FAILURE_ROLLBACK_0:
        if (framePtr != NULL)
        {
            call NumFramesFreedByDefragmenterStat.increment(1);
            call Ieee154FrameAllocator.freeFrame(framePtr);
        }
        return err;
    }



    event void Ieee154FrameReceiver.frameReceivingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        local_dbg("[6LoWPAN::Defragmenter] The defragmenter has been informed "
            "that receiving frame %lu has finished with status %u.\r\n",
            (long unsigned)framePtr, (unsigned)status);
        if (call IsOnBit.isClear() || call Ieee154FrameQueue.isFull())
        {
            local_dbg("[6LoWPAN::Defragmenter] The defragmenter is off or "
                "its queue is full. Dropping the frame.\r\n");
            call NumFramesFreedByDefragmenterStat.increment(1);
            call Ieee154FrameAllocator.freeFrame(framePtr);
            return;
        }
        if (status == SUCCESS)
        {
            call NumFramesReceivedByDefragmenterStat.increment(1);
            call Ieee154FrameQueue.enqueueLast(framePtr);
            local_dbg("[6LoWPAN::Defragmenter] The received frame was enqueued "
                "for further processing.\r\n");
            startReceivingFrame(NULL);
            startProcessingFrameIfNecessary(framePtr);
        }
        else
        {
            local_dbg("[6LoWPAN::Defragmenter] The defragmenter will ignore "
                "the erroneous frame reception.\r\n");
            startReceivingFrame(framePtr);
        }
    }



    void startProcessingFrameIfNecessary(whip6_ieee154_dframe_info_t * framePtr)
    {
        if (call Ieee154FrameQueue.getSize() == 1)
        {
            m_processedPacket = NULL;
            m_readyPacket = NULL;
            m_doneUntilNow = DONE_NOTHING;
            post processReceivedFrameTask();
        }
    }



    task void processReceivedFrameTask()
    {
        whip6_ieee154_dframe_info_t *   framePtr;
        bool                            continueProcessing = FALSE;
        if (call Ieee154FrameQueue.isEmpty() || call IsOnBit.isClear())
        {
            return;
        }
        if (m_processedPacket == NULL && call TimeoutPendingBit.isSet())
        {
            tryToHandlePeriodicTimeout();
            post processReceivedFrameTask();
            return;
        }
        framePtr = call Ieee154FrameQueue.peekFirst();
        local_dbg("[6LoWPAN::Defragmenter] Processing the received frame, %lu.\r\n",
            (long unsigned)framePtr);
        switch (m_doneUntilNow)
        {
        case DONE_NOTHING:
            continueProcessing = unpack6LoWPANHeaders(framePtr);
            break;
        case DONE_UNPACK_6LOWPAN_HDRS:
            continueProcessing = startDefragmentationIfRequired(framePtr);
            break;
        case DONE_LOCK_IPV6_PACKET:
            continueProcessing = mergeFragmentToPacket(framePtr);
            break;
        case DONE_DEFRAGMENTING_IPV6_PACKET:
            continueProcessing = deliverDefragmentedPacket();
            break;
        };
        if (!continueProcessing)
        {
            local_dbg("[6LoWPAN::Defragmenter] Processing the received frame, %lu, has stopped.\r\n",
                (long unsigned)framePtr);
            stopProcessingFrameAndStartReceivingNewOne();
        }
    }



    bool unpack6LoWPANHeaders(whip6_ieee154_dframe_info_t * framePtr)
    {
        whip6_error_t   err;
        
        err =
            whip6_lowpanFrameHeadersUnpack(
                    &m_unpackedHeaders,
                    framePtr
            );
        if (err != WHIP6_NO_ERROR)
        {
            local_dbg("[6LoWPAN::Defragmenter] Failed to unpack the 6LoWPAN headers "
                "in the received frame, %lu.\r\n", (long unsigned)framePtr);
            return FALSE;
        }
        whip6_lowpanDefragmenterCreateVirtualMeshHeaderIfNecessary(
                framePtr,
                &m_unpackedHeaders
        );
        m_doneUntilNow = DONE_UNPACK_6LOWPAN_HDRS;
        post processReceivedFrameTask();
        local_dbg("[6LoWPAN::Defragmenter] Unpacked the 6LoWPAN headers "
            "in the received frame, %lu.\r\n", (long unsigned)framePtr);
        if (whip6_lowpanFrameHeadersHasBc0Header(&m_unpackedHeaders))
        {
            whip6_ieee154DFrameGetDstAddr(framePtr, &m_ieee154AddrScratchpad);
            if (whip6_ieee154AddrAnyIsBroadcast(&m_ieee154AddrScratchpad))
            {
                whip6_ieee154DFrameGetSrcAddr(framePtr, &m_ieee154AddrScratchpad);
                updateLinkTableFromBC0Header(
                        call Ieee154UnpackedDataFrameMetadata.wasPhysicalSignalQualityHighUponRx(
                                framePtr
                        )
                );
            }
        }
        return TRUE;
    }



    void updateLinkTableFromBC0Header(bool allowReplacement)
    {
        lowpan_link_index_t   linkIdx;
        local_dbg("[6LoWPAN::Defragmenter] Using the BC0 6LoWPAN header "
            "to update the neighbor table with replacement %s.\r\n",
            allowReplacement ? "allowed" : "prohibited");
        linkIdx =
                call LoWPANLinkTable.findExistingLinkOrCreateNewOne(
                        &m_ieee154AddrScratchpad,
                        allowReplacement
                );
        if (linkIdx != WHIP6_6LOWPAN_INVALID_LINK_IDX)
        {
            local_dbg("[6LoWPAN::Defragmenter] Reporting sequence number %u "
                "from the BC0 6LoWPAN header for the link with index %u "
                "in the neighbor table.\r\n",
                (unsigned)whip6_lowpanFrameHeadersGetBc0HeaderSeqNo(&m_unpackedHeaders),
                (unsigned)linkIdx);
            call LoWPANLinkTable.reportBroadcastReceptionForLink(
                    linkIdx,
                    whip6_lowpanFrameHeadersGetBc0HeaderSeqNo(&m_unpackedHeaders)
            );
        }
    }



    bool startDefragmentationIfRequired(whip6_ieee154_dframe_info_t * framePtr)
    {
        if (whip6_lowpanFrameHeadersHasFragHeader(&m_unpackedHeaders))
        {
            local_dbg("[6LoWPAN::Defragmenter] The received frame, %lu, has a fragmentation header.\r\n",
                (long unsigned)framePtr);
            m_processedPacket =
                whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt(
                        &m_state,
                        framePtr,
                        &m_unpackedHeaders,
                        call ReassemblyTimeoutTimer.getNow()
                );
            if (m_processedPacket == NULL)
            {
                local_dbg("[6LoWPAN::Defragmenter] Unable to find nor create an IPv6 packet for the frame.\r\n");
                return FALSE;
            }
            local_dbg("[6LoWPAN::Defragmenter] Found or created packet %lu for frame %lu.\r\n",
                (long unsigned)m_processedPacket, (long unsigned)framePtr);
            m_doneUntilNow = DONE_LOCK_IPV6_PACKET;
        }
        else
        {
            local_dbg("[6LoWPAN::Defragmenter] The received frame, %lu, has no fragmentation header.\r\n",
                (long unsigned)framePtr);
            m_readyPacket =
                whip6_lowpanDefragmenterPassFrameWithEntireIpv6Packet(
                        &m_state,
                        framePtr,
                        &m_unpackedHeaders
                );
            if (m_readyPacket == NULL)
            {
                // We haven't managed to get a full
                // packet. The processing ends here.
                local_dbg("[6LoWPAN::Defragmenter] Unable to extract an IPv6 packet from the frame.\r\n");
                return FALSE;
            }
            // We have managed to get a full packet.
            local_dbg("[6LoWPAN::Defragmenter] Extracted packet %lu from frame %lu.\r\n",
                (long unsigned)m_readyPacket, (long unsigned)framePtr);
            whip6_ieee154DFrameGetSrcAddr(
                    framePtr,
                    &m_unpackedHeaders.mesh.srcAddr
            );
            m_doneUntilNow = DONE_DEFRAGMENTING_IPV6_PACKET;
        }
        post processReceivedFrameTask();
        return TRUE;
    }



    bool mergeFragmentToPacket(whip6_ieee154_dframe_info_t * framePtr)
    {
        local_dbg("[6LoWPAN::Defragmenter] Merging frame %lu into packet %lu.\r\n",
            (long unsigned)framePtr, (long unsigned)m_processedPacket);
        m_readyPacket =
            whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment(
                    &m_state,
                    framePtr,
                    &m_unpackedHeaders,
                    m_processedPacket
            );
        m_processedPacket = NULL;
        if (m_readyPacket == NULL)
        {
            // We haven't managed to get a full
            // packet yet. The processing ends here.
            local_dbg("[6LoWPAN::Defragmenter] The frame did not complete any packet.\r\n");
            return FALSE;
        }
        // We have managed to get a full packet.
        local_dbg("[6LoWPAN::Defragmenter] The frame completed packet %lu.\r\n",
            (long unsigned)m_readyPacket);
        whip6_ieee154DFrameGetSrcAddr(
                framePtr,
                &m_unpackedHeaders.mesh.srcAddr
        );
        m_doneUntilNow = DONE_DEFRAGMENTING_IPV6_PACKET;
        post processReceivedFrameTask();
        return TRUE;
    }



    inline bool deliverDefragmentedPacket()
    {
        whip6_ipv6_packet_t * packet = m_readyPacket;
        m_readyPacket = NULL;
        local_dbg("[6LoWPAN::Defragmenter] Delivering defragmented packet %lu.\r\n",
            (long unsigned)packet);
        call NumPacketsFinishedBeingDefragmentedStat.increment(1);
        signal Defragmenter.defragmentingIpv6PacketFinished(
                packet,
                &m_unpackedHeaders.mesh.srcAddr
        );
        return FALSE;
    }



    void stopProcessingFrameAndStartReceivingNewOne()
    {
        whip6_ieee154_dframe_info_t * framePtr;
        m_doneUntilNow = DONE_NOTHING;
        if (m_readyPacket != NULL)
        {
            whip6_ipv6FreeExistingIPv6Packet(m_readyPacket);
            m_readyPacket = NULL;
        }
        if (m_processedPacket != NULL)
        {
            local_dbg("[6LoWPAN::Defragmenter] Unlocking packet %lu.\r\n",
                (long unsigned)m_processedPacket);
            whip6_lowpanDefragmenterUnlockPacket(
                    &m_state,
                    m_processedPacket
            );
            m_processedPacket = NULL;
        }
        framePtr = call Ieee154FrameQueue.peekFirst();
        call Ieee154FrameQueue.dequeueFirst();
        startReceivingFrame(framePtr);
        local_dbg("[6LoWPAN::Defragmenter] The defragmenter has %u frames in its queue.\r\n",
            (unsigned)call Ieee154FrameQueue.getSize());
        if (! call Ieee154FrameQueue.isEmpty())
        {
            post processReceivedFrameTask();
        }
    }



    event void ReassemblyTimeoutTimer.fired()
    {
        if (call IsOnBit.isClear())
        {
            return;
        }
        local_dbg("[6LoWPAN::Defragmenter] A periodic timeout has been signaled.\r\n");
        call ReassemblyTimeoutTimer.startWithTimeoutFromNow(
                (call ReassemblyTimeoutInMillis.get()) >> 1
        );
        tryToHandlePeriodicTimeout();
    }



    void tryToHandlePeriodicTimeout()
    {
        local_dbg("[6LoWPAN::Defragmenter] Trying to handle a periodic timeout.\r\n");
        if (whip6_lowpanDefragmenterPeriodicTimeout(
                &m_state,
                call ReassemblyTimeoutTimer.getNow(),
                call ReassemblyTimeoutInMillis.get()
            ) != WHIP6_NO_ERROR)
        {
            local_dbg("[6LoWPAN::Defragmenter] Unable to handle the timeout now.\r\n");
            call TimeoutPendingBit.set();
        }
        else
        {
            local_dbg("[6LoWPAN::Defragmenter] Successfully handled the timeout.\r\n");
            call TimeoutPendingBit.clear();
        }
    }



    default event inline void Defragmenter.defragmentingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr
    )
    {
        whip6_ipv6FreeExistingIPv6Packet(packet);
    }



    default command inline lowpan_link_index_t LoWPANLinkTable.findExistingLinkOrCreateNewOne(
            whip6_ieee154_addr_t const * addr,
            bool allowReplacing
    )
    {
        return WHIP6_6LOWPAN_INVALID_LINK_IDX;
    }



    default command inline void LoWPANLinkTable.reportBroadcastReceptionForLink(
            lowpan_link_index_t idx,
            lowpan_header_bc0_seq_no_t seqNo
    )
    {
        // Do nothing.
    }



    default command inline bool Ieee154UnpackedDataFrameMetadata.wasPhysicalSignalQualityHighUponRx(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        return FALSE;
    }



    default command inline void NumPacketsFinishedBeingDefragmentedStat.increment(uint8_t val)
    {
    }



    default command inline void NumFramesReceivedByDefragmenterStat.increment(uint8_t val)
    {
    }



    default command inline void NumFramesAllocatedByDefragmenterStat.increment(uint8_t val)
    {
    }



    default command inline void NumFramesFreedByDefragmenterStat.increment(uint8_t val)
    {
    }

#undef local_dbg

}
