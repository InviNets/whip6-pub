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
#include <6lowpan/uc6LoWPANFragmentation.h>
#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>



/**
 * The main module of a fragmenter of 6LoWPAN frames.
 *
 * @param frag_packet_pool_size The maximal number of
 *   packets that can be concurrently fragmented. Zero
 *   means that all packets must fit in a single frame.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANFragmenterMainPrv(
    uint8_t frag_packet_pool_size
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANFragmenter as Fragmenter;
    }
    uses
    {
        interface Bit as IsOnBit @exactlyonce();
        interface Queue<uint8_t, uint8_t> as JobQueue @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumPacketsPassedForFragmentationStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStartedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStoppedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumFramesRequestedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesObtainedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesReleasedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumStartedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as NumFinishedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterStartedForwardingStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterCanceledForwardingStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterFinishedForwardingStat;
    }
}
implementation
{

    enum
    {
        FRAG_PACKET_POOL_SIZE = frag_packet_pool_size,
    };

    enum
    {
        TOKEN_FLAG_FAILED = (1 << 5),
        TOKEN_FLAG_CANCELED = (1 << 6),
        TOKEN_FLAG_PROCESSED = (1 << 7),
    };

    whip6_lowpan_frag_global_state_t        m_state;
    whip6_lowpan_frag_packet_state_t        m_fragPacketPool[FRAG_PACKET_POOL_SIZE];
    whip6_lowpan_frag_packet_state_t *      m_tokenPtrs[FRAG_PACKET_POOL_SIZE];
    whip6_ieee154_dframe_info_t *           m_tokenReadyFrames[FRAG_PACKET_POOL_SIZE];
    whip6_ieee154_dframe_info_t *           m_tokenSentFrames[FRAG_PACKET_POOL_SIZE];
    uint8_t                                 m_tokenFlags[FRAG_PACKET_POOL_SIZE];
    whip6_lowpan_unpacked_frame_headers_t   m_default6LoWPANHeaders;



    task void fragmentationTask();
    void postFragmentationTaskForTokenIfNecessary(uint8_t token);
    void finishFragmentingPacket(uint8_t token, error_t status);
    bool attemptToReserveFrame(uint8_t token);
    void obtainNextFragment(uint8_t token);
    void sendFrameWithFragment(uint8_t token);

//#define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    command error_t SynchronousStarter.start()
    {
        uint8_t i;
        local_dbg("[6LoWPAN::Fragmenter] Starting the IPv6 packet fragmenter.\r\n");
        if (call IsOnBit.isSet())
        {
            local_dbg("[6LoWPAN::Fragmenter] The IPv6 packet fragmenter is already running.\r\n");
            return EALREADY;
        }
        call IsOnBit.set();
        whip6_lowpanFragmenterInit(
                &m_state,
                m_fragPacketPool,
                FRAG_PACKET_POOL_SIZE
        );
        for (i = 0; i < FRAG_PACKET_POOL_SIZE; ++i)
        {
            m_tokenPtrs[i] = NULL;
            m_tokenReadyFrames[i] = NULL;
            m_tokenSentFrames[i] = NULL;
            m_tokenFlags[i] = 0;
        }
        call JobQueue.clear();
        whip6_lowpanFrameHeadersNew(&m_default6LoWPANHeaders);
        local_dbg("[6LoWPAN::Fragmenter] Started the IPv6 packet fragmenter.\r\n");
        return SUCCESS;
    }



    command uint8_t Fragmenter.startFragmentingIpv6Packet(
        whip6_ipv6_packet_t * packet,
        whip6_lowpan_unpacked_frame_headers_t * loWPANHdrs
    )
    {
        whip6_lowpan_frag_packet_state_t *   fragPacket;
        uint8_t                              token;

        local_dbg("[6LoWPAN::Fragmenter] Starting to fragment packet %lu.\r\n",
            (long unsigned)packet);
        call NumPacketsPassedForFragmentationStat.increment(1);
        if (call IsOnBit.isClear())
        {
            local_dbg("[6LoWPAN::Fragmenter] The fragmenter is off.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        fragPacket =
            whip6_lowpanFragmenterStartFragmentingIpv6Packet(
                    &m_state,
                    packet
            );
        if (fragPacket == NULL)
        {
            local_dbg("[6LoWPAN::Fragmenter] uC error when starting fragmenting the packet.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        if (loWPANHdrs == NULL)
        {
            local_dbg("[6LoWPAN::Fragmenter] Using the default 6LoWPAN headers.\r\n");
            loWPANHdrs = &m_default6LoWPANHeaders;
        }
        if (whip6_lowpanFragmenterProvideAdditional6LoWPANHeadersForIpv6Packet(&m_state, fragPacket, loWPANHdrs) != WHIP6_NO_ERROR)
        {
            local_dbg("[6LoWPAN::Fragmenter] uC error when setting 6LoWPAN headers.\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        // NOTICE iwanicki 2013-04-29:
        // Well, we could reduce the cost to a constant
        // if we employed another queue, but who cares.
        for (token = 0; token < FRAG_PACKET_POOL_SIZE; ++token)
        {
            if (m_tokenPtrs[token] == NULL)
            {
                break;
            }
        }
        if (token >= FRAG_PACKET_POOL_SIZE)
        {
            // This should not happen.
            local_dbg("[6LoWPAN::Fragmenter] No free token for the packet.\r\n");
            goto FAILURE_ROLLBACK_1;
        }
        m_tokenPtrs[token] = fragPacket;
        m_tokenReadyFrames[token] = NULL;
        m_tokenSentFrames[token] = NULL;
        m_tokenFlags[token] = 0;
        postFragmentationTaskForTokenIfNecessary(token);
        local_dbg("[6LoWPAN::Fragmenter] Packet fragmentation started successfully (token=%u).\r\n", (unsigned)token + 1);
        call NumPacketsStartedBeingFragmentedStat.increment(1);
        return token + 1;

    FAILURE_ROLLBACK_1:
        whip6_lowpanFragmenterFinishFragmentingIpv6Packet(&m_state, fragPacket);
    FAILURE_ROLLBACK_0:
        return 0;
    }



    void postFragmentationTaskForTokenIfNecessary(uint8_t token)
    {
        if ((m_tokenFlags[token] & TOKEN_FLAG_PROCESSED) == 0)
        {
            m_tokenFlags[token] |= TOKEN_FLAG_PROCESSED;
            call JobQueue.enqueueLast(token);
            call NumStartedInternalFragmenterJobsStat.increment(1);
            post fragmentationTask();
        }
    }



    command uint8_t Fragmenter.stopFragmentingIpv6Packet(uint8_t token)
    {
        if (token == 0 || token > FRAG_PACKET_POOL_SIZE)
        {
            return EINVAL;
        }
        --token;
        if (m_tokenPtrs[token] == NULL)
        {
            return EINVAL;
        }
        if ((m_tokenFlags[token] & TOKEN_FLAG_CANCELED) != 0)
        {
            return EALREADY;
        }
        m_tokenFlags[token] |= TOKEN_FLAG_CANCELED;
        postFragmentationTaskForTokenIfNecessary(token);
        call NumPacketsStoppedBeingFragmentedStat.increment(1);
        return SUCCESS;
    }



    task void fragmentationTask()
    {
        uint8_t token;

        if (call JobQueue.isEmpty())
        {
            return;
        }
        token = call JobQueue.peekFirst();
        call JobQueue.dequeueFirst();
        call NumFinishedInternalFragmenterJobsStat.increment(1);

        local_dbg("[6LoWPAN::Fragmenter] Fragmenting the packet with token %u (ptr=%lu; flags=%u; offset=%u; length=%u).\r\n",
                (unsigned)token + 1,
                (long unsigned)m_tokenPtrs[token],
                (unsigned)m_tokenFlags[token],
                (unsigned)m_tokenPtrs[token]->fragOffset,
                (unsigned)whip6_ipv6BasicHeaderGetPayloadLength(&m_tokenPtrs[token]->packet->header) + sizeof(ipv6_basic_header_t));

        m_tokenFlags[token] &= ~(uint8_t)TOKEN_FLAG_PROCESSED;

        if ((m_tokenFlags[token] & (TOKEN_FLAG_CANCELED | TOKEN_FLAG_FAILED)) != 0)
        {
            // The packet is canceled or has failed.
            local_dbg("[6LoWPAN::Fragmenter] The packet with token %u is marked as failed.\r\n",
                    (unsigned)token + 1);
            if (m_tokenReadyFrames[token] != NULL)
            {
                local_dbg("[6LoWPAN::Fragmenter] Releasing the packet's ready frame.\r\n");
                call NumFramesReleasedByFragmenterStat.increment(1);
                signal Fragmenter.frameForFragmentedPacketReleased(
                    token + 1,
                    m_tokenReadyFrames[token]
                );
                m_tokenReadyFrames[token] = NULL;
            }
            if (m_tokenSentFrames[token] != NULL)
            {
                local_dbg("[6LoWPAN::Fragmenter] Attempting to cancel sending the packet's frame.\r\n");
                if (call Ieee154FrameSender.stopSendingFrame(m_tokenSentFrames[token]) == SUCCESS)
                {
                    local_dbg("[6LoWPAN::Fragmenter] Sending the packet's frame has been canceled.\r\n");
                    call NumFramesFragmenterCanceledForwardingStat.increment(1);
                    call NumFramesReleasedByFragmenterStat.increment(1);
                    signal Fragmenter.frameForFragmentedPacketReleased(
                        token + 1,
                        m_tokenSentFrames[token]
                    );
                    m_tokenSentFrames[token] = NULL;
                }
            }
            if (m_tokenSentFrames[token] == NULL)
            {
                finishFragmentingPacket(
                    token,
                    (m_tokenFlags[token] & TOKEN_FLAG_CANCELED) != 0 ?
                        ECANCEL :
                        FAIL
                );
            }
        }
        else if (whip6_lowpanFragmenterDoesNextFragmentOfIpv6PacketExist(&m_state, m_tokenPtrs[token]))
        {
            // The packet is still being fragmented...
            local_dbg("[6LoWPAN::Fragmenter] The packet with token %u still has portions to fragment.\r\n",
                    (unsigned)token + 1);
            if (m_tokenReadyFrames[token] == NULL)
            {
                // ... but we have no next frame
                local_dbg("[6LoWPAN::Fragmenter] Attempting to allocate a frame for the packet with token %u.\r\n",
                        (unsigned)token + 1);
                if (attemptToReserveFrame(token))
                {
                    obtainNextFragment(token);
                }
            }
            else
            {
                // ... and we have a next frame...
                local_dbg("[6LoWPAN::Fragmenter] The packet with token %u has a frame ready for sending.\r\n",
                        (unsigned)token + 1);
                if (m_tokenSentFrames[token] == NULL)
                {
                    sendFrameWithFragment(token);
                }
            }            
        }
        else
        {
            // The packet has been fragmented successfully.
            local_dbg("[6LoWPAN::Fragmenter] The packet with token %u has no more portions to fragment.\r\n",
                    (unsigned)token + 1);
            if (m_tokenReadyFrames[token] == NULL)
            {
                local_dbg("[6LoWPAN::Fragmenter] The packet with token %u has no frame ready for sending.\r\n",
                        (unsigned)token + 1);
                // ... and there is no next frame pending ...
                if (m_tokenSentFrames[token] == NULL)
                {
                    finishFragmentingPacket(token, SUCCESS);
                }
                // If some frame is being sent, the sending
                // will finish eventually.
            }
            else if (m_tokenSentFrames[token] == NULL)
            {
                // ... and some frame is pending,
                // but no frame is being sent.
                local_dbg("[6LoWPAN::Fragmenter] The packet with token %u has a frame ready for sending.\r\n",
                        (unsigned)token + 1);
                sendFrameWithFragment(token);
            }
            // If there is some pending frame and some frame
            // is being sent, the sending will end eventually.
        }

        if (! call JobQueue.isEmpty())
        {
            post fragmentationTask();
        }
    }



    void finishFragmentingPacket(uint8_t token, error_t status)
    {
        whip6_ipv6_packet_t * packet;
        packet =
            whip6_lowpanFragmenterFinishFragmentingIpv6Packet(
                    &m_state,
                    m_tokenPtrs[token]
            );
        m_tokenPtrs[token] = NULL;
        m_tokenFlags[token] = 0;
        local_dbg("[6LoWPAN::Fragmenter] Finishing fragmenting packet %lu with token %u.\r\n",
                (unsigned long)packet, (unsigned)token + 1);
        call NumPacketsFinishedBeingFragmentedStat.increment(1);
        signal Fragmenter.fragmentingIpv6PacketFinished(packet, token + 1, status);
    }



    bool attemptToReserveFrame(uint8_t token)
    {
        call NumFramesRequestedByFragmenterStat.increment(1);
        m_tokenReadyFrames[token] =
            signal Fragmenter.frameForFragmentedPacketRequested(token + 1);
        if (m_tokenReadyFrames[token] != NULL)
        {
            local_dbg("[6LoWPAN::Fragmenter] Obtained frame %lu for a fragment of the packet with token %u.\r\n",
                (unsigned long)m_tokenReadyFrames[token], (unsigned)token + 1);
            call NumFramesObtainedByFragmenterStat.increment(1);
            return TRUE;
        }
        local_dbg("[6LoWPAN::Fragmenter] Failed to obtain a frame for the packet with token %u.\r\n",
            (unsigned)token + 1);
        if (m_tokenSentFrames[token] == NULL)
        {
            local_dbg("[6LoWPAN::Fragmenter] Marking the packet with token %u as failed.\r\n",
                (unsigned)token + 1);
            m_tokenFlags[token] |= TOKEN_FLAG_FAILED;
            postFragmentationTaskForTokenIfNecessary(token);
        }
        return FALSE;
    }



    void obtainNextFragment(uint8_t token)
    {
        if (whip6_lowpanFragmenterRequestNextFragmentOfIpv6Packet(&m_state, m_tokenPtrs[token], m_tokenReadyFrames[token]) != WHIP6_NO_ERROR)
        {
            local_dbg("[6LoWPAN::Fragmenter] Failed to obtain the next fragment of packet with token %u.\r\n",
                (unsigned)token + 1);
            m_tokenFlags[token] |= TOKEN_FLAG_FAILED;
        }
        postFragmentationTaskForTokenIfNecessary(token);
    }



    void sendFrameWithFragment(uint8_t token)
    {
        local_dbg("[6LoWPAN::Fragmenter] Sending a frame for the packet with token %u.\r\n",
            (unsigned)token + 1);
        if (call Ieee154FrameSender.startSendingFrame(m_tokenReadyFrames[token]) == SUCCESS)
        {
            local_dbg("[6LoWPAN::Fragmenter] Sending a frame for the packet with token %u succeeded.\r\n",
                (unsigned)token + 1);
            m_tokenSentFrames[token] = m_tokenReadyFrames[token];
            m_tokenReadyFrames[token] = NULL;
            call NumFramesFragmenterStartedForwardingStat.increment(1);
        }
        else
        {
            local_dbg("[6LoWPAN::Fragmenter] Sending a frame for the packet with token %u failed.\r\n",
                (unsigned)token + 1);
            m_tokenFlags[token] |= TOKEN_FLAG_FAILED;
        }
        postFragmentationTaskForTokenIfNecessary(token);
    }



    event void Ieee154FrameSender.frameSendingFinished(
            whip6_ieee154_dframe_info_t * framePtr,
            error_t status
    )
    {
        uint8_t token;
        // Find the packet corresponding to the frame.
        for (token = 0; token < FRAG_PACKET_POOL_SIZE; ++token)
        {
            if (m_tokenSentFrames[token] == framePtr)
            {
                break;
            }
        }
        if (token >= FRAG_PACKET_POOL_SIZE)
        {
            // We are not aware of the frame ... strange.
            local_dbg("[6LoWPAN::Fragmenter] ERROR finished sending an unknown frame in file %s, line %d.\r\n",
                __FILE__, __LINE__);
            return;
        }
        call NumFramesFragmenterFinishedForwardingStat.increment(1);
        local_dbg("[6LoWPAN::Fragmenter] Finished sending the frame of the packet with token %u.\r\n",
            (unsigned)token + 1);
        m_tokenSentFrames[token] = NULL;
        if (status != SUCCESS)
        {
            local_dbg("[6LoWPAN::Fragmenter] The sending failed.\r\n");
            m_tokenFlags[token] |= TOKEN_FLAG_FAILED;
        }
        postFragmentationTaskForTokenIfNecessary(token);
        call NumFramesReleasedByFragmenterStat.increment(1);
        signal Fragmenter.frameForFragmentedPacketReleased(token + 1, framePtr);
    }



    default event inline void Fragmenter.fragmentingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            uint8_t token,
            error_t status
    )
    {
        whip6_ipv6FreeExistingIPv6Packet(packet);
    }



    default inline command void NumPacketsPassedForFragmentationStat.increment(uint8_t val)
    {
    }



    default inline command void NumPacketsStartedBeingFragmentedStat.increment(uint8_t val)
    {
    }



    default inline command void NumPacketsStoppedBeingFragmentedStat.increment(uint8_t val)
    {
    }



    default inline command void NumPacketsFinishedBeingFragmentedStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesRequestedByFragmenterStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesObtainedByFragmenterStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesReleasedByFragmenterStat.increment(uint8_t val)
    {
    }



    default inline command void NumStartedInternalFragmenterJobsStat.increment(uint8_t val)
    {
    }



    default inline command void NumFinishedInternalFragmenterJobsStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesFragmenterStartedForwardingStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesFragmenterCanceledForwardingStat.increment(uint8_t val)
    {
    }



    default inline command void NumFramesFragmenterFinishedForwardingStat.increment(uint8_t val)
    {
    }

#undef local_dbg
}
