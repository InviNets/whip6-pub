/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>



/**
 * The main module for processing incoming
 * IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6IncomingPacketProcessorMainPrv()
{
    provides
    {
        interface IPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId];
    }
    uses
    {
        interface IPv6PacketReceiver as SubIPv6PacketReceiver[ipv6_net_iface_id_t ifaceId];
        interface IPv6InterfaceStateProvider as SubInterfaceStateProvider[ipv6_net_iface_id_t ifaceId];
        interface Queue<whip6_ipv6_in_packet_processing_state_t *, uint8_t> as ProcessedPacketQueue;
    }
}
implementation
{


// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)



    uint8_t findQueueIndexOfProcessedPacket(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    );
    void finishHandlingPacket(uint8_t idx, error_t status);
    task void continueProcessingPacketTask();



    event error_t SubIPv6PacketReceiver.startReceivingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        whip6_ipv6_basic_header_t *              hdr;
        ipv6_hop_limit_t                         hopLimit;
        error_t                                  status = FAIL;

        local_dbg("[IPv6:InPacketProcessor] Trying to initiate processing "
            "of an incoming packet state, %lu, which corresponds to packet %lu.\r\n",
            (long unsigned)inPacket, (long unsigned)inPacket->packet);

        local_assert(call SubInterfaceStateProvider.getInterfaceStatePtr[ifaceId]() != NULL);
        local_assert(inPacket->packet != NULL);
        local_assert((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE) == 0);
        local_assert((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED) == 0);

        if (call ProcessedPacketQueue.isFull())
        {
            local_dbg("[IPv6:InPacketProcessor] No queue space for processing the "
                "incoming packet state, %lu.\r\n", (long unsigned)inPacket);

            status = ENOMEM;
            goto FAILURE_ROLLBACK_0;
        }

        hdr = &inPacket->packet->header;

        local_dbg("[IPv6:InPacketProcessor] The packet has a %lu-byte payload.\r\n",
            (long unsigned)whip6_ipv6BasicHeaderGetPayloadLength(hdr));

        if (whip6_ipv6BasicHeaderGetVersion(hdr) != WHIP6_IPV6_PROTOCOL_VERSION)
        {
            local_dbg("[IPv6:InPacketProcessor] The incoming packet state, "
                "%lu, does not correspond to a valid IPv6 packet.\r\n",
                (long unsigned)inPacket);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }

        hopLimit = whip6_ipv6BasicHeaderGetHopLimit(hdr);
        if (hopLimit == 0)
        {
            local_dbg("[IPv6:InPacketProcessor] The incoming packet state, "
                "%lu, corresponds to packet with a zero hop limit.\r\n",
                (long unsigned)inPacket);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        --hopLimit;
        whip6_ipv6BasicHeaderSetHopLimit(hdr, hopLimit);
        
        if (whip6_ipv6AddrBelongsToInterface(
                call SubInterfaceStateProvider.getInterfaceStatePtr[ifaceId](),
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(hdr))
        )
        {
            local_dbg("[IPv6:InPacketProcessor] The packet is destined to the node.\r\n");

            inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_DESTINED_AT_IFACE;
        }

        whip6_iovIteratorInitToBeginning(
                inPacket->packet->firstPayloadIov,
                &inPacket->payloadIter
        );
        inPacket->payloadOffset = 0;
        inPacket->ifaceId = ifaceId;
        inPacket->nextHeaderId = whip6_ipv6BasicHeaderGetNextHeader(hdr);

        post continueProcessingPacketTask();
        call ProcessedPacketQueue.enqueueLast(inPacket);

        local_dbg("[IPv6:InPacketProcessor] Enqueued the incoming packet "
            "state, %lu, for processing.\r\n", (long unsigned)inPacket);
        
        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void continueProcessingPacketTask()
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;
        uint8_t                                     i, n;
        error_t                                     status;

        for (i = 0, n = call ProcessedPacketQueue.getSize(); i < n; ++i)
        {
            inPacket = call ProcessedPacketQueue.peekIth(i);

            if ((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED) == 0)
            {
                post continueProcessingPacketTask();

                if (inPacket->nextHeaderId == WHIP6_IANA_IPV6_NO_NEXT_HEADER)
                {
                    if (! whip6_iovIteratorIsValid(&inPacket->payloadIter))
                    {
                        inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE;
                    }
                }

                if ((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE) != 0)
                {
                    local_dbg("[IPv6:InPacketProcessor] Successfully finished "
                        "the processing of incoming packet state %lu, which "
                        "corresponds to packet %lu.\r\n", (long unsigned)inPacket,
                        (long unsigned)inPacket->packet);

                    finishHandlingPacket(i, SUCCESS);
                    return;
                }

                inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED;

                status =
                        signal IPv6PacketReceiver.startReceivingIPv6Packet[inPacket->nextHeaderId](
                                inPacket
                        );

                if (status != SUCCESS)
                {
                    local_dbg("[IPv6:InPacketProcessor] Failed to dispatch "
                        "the processing of incoming packet state %lu to "
                        "the handler with id %u. Finishing the processing.\r\n",
                        (long unsigned)inPacket, (unsigned)inPacket->nextHeaderId);
                    
                    inPacket->flags &= ~(uint8_t)WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED;
                    inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE;
                    finishHandlingPacket(i, status);
                }
                else
                {
                    local_dbg("[IPv6:InPacketProcessor] Dispatched the "
                        "processing of incoming packet state %lu to "
                        "the handler with id %u.\r\n", (long unsigned)inPacket,
                        (unsigned)inPacket->nextHeaderId);
                }

                return;
            }
        }
        local_dbg("[IPv6:InPacketProcessor] No incoming packets can be processed at the moment.\r\n");
    }



    command void IPv6PacketReceiver.finishReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        uint8_t    i;

        inPacket->flags &= ~(uint8_t)WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED;

        if (status == SUCCESS)
        {
            local_assert((unsigned)nxtHdrId != (unsigned)inPacket->nextHeaderId);
            local_dbg("[IPv6:InPacketProcessor] The processing of incoming "
                "packet state %lu by the handler with id %u has finished "
                "successfully. Continuing the processing with the next handler, %u.\r\n",
                (long unsigned)inPacket, (unsigned)nxtHdrId,
                (unsigned)inPacket->nextHeaderId);

            post continueProcessingPacketTask();
        }
        else
        {
            local_dbg("[IPv6:InPacketProcessor] The processing of incoming "
                "packet state %lu by the handler with id %u has failed. "
                "Finishing the entire processing.\r\n",
                (long unsigned)inPacket, (unsigned)nxtHdrId);
                    
            inPacket->flags |= WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE;
            i = findQueueIndexOfProcessedPacket(inPacket);
            if (i >= call ProcessedPacketQueue.getSize())
            {
                return;
            }
            finishHandlingPacket(i, status);
        }
    }



    uint8_t findQueueIndexOfProcessedPacket(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        uint8_t const   n = call ProcessedPacketQueue.getSize();
        uint8_t         i;
        for (i = 0; i < n; ++i)
        {
            if (call ProcessedPacketQueue.peekIth(i) == inPacket)
            {
                return i;
            }
        }
        return n;
    }



    void finishHandlingPacket(uint8_t idx, error_t status)
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;

        inPacket = call ProcessedPacketQueue.peekIth(idx);
        call ProcessedPacketQueue.dequeueIth(idx);
        call SubIPv6PacketReceiver.finishReceivingIPv6Packet[inPacket->ifaceId](inPacket, status);
    }



    default event inline error_t IPv6PacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return FAIL;
    }



    default command inline void SubIPv6PacketReceiver.finishReceivingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        local_assert(FALSE);
    }



    default command inline whip6_ipv6_net_iface_generic_state_t * SubInterfaceStateProvider.getInterfaceStatePtr[ipv6_net_iface_id_t ifaceId]()
    {
        return NULL;
    }

#undef local_dbg

}
