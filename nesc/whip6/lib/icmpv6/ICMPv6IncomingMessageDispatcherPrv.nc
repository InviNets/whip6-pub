/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

#include <base/ucIoVec.h>
#include <base/ucString.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6Checksum.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>



/**
 * The module for dispatching incoming ICMPv6
 * messages to appropriate handlers.
 *
 * @author Konrad Iwanicki
 */
generic module ICMPv6IncomingMessageDispatcherPrv()
{
    provides
    {
        interface Init @exactlyonce();
        interface ICMPv6MessageReceiver[icmpv6_message_type_t msgType];
    }
    uses
    {
        interface IPv6PacketReceiver as PacketReceiver @exactlyonce();
        interface Queue<whip6_ipv6_in_packet_processing_state_t *, uint8_t> as ProcessedPacketQueue @exactlyonce();
        interface IPv6ChecksumComputer as ChecksumComputer @exactlyonce();
        interface Bit as PacketReadyBit @exactlyonce();
    }
}
implementation
{

    whip6_icmpv6_message_header_t               m_msgHeader;
    whip6_iov_blist_iter_t                      m_msgChecksumIter;
    whip6_ipv6_checksum_computation_t           m_msgChecksumComp;
    whip6_ipv6_in_packet_processing_state_t *   m_dispatchedPktPtr = NULL;


    void finishProcessingFirstQueuedICMPv6Message(error_t status);
    void finishProcessingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    );

    task void startProcessingICMPv6MessageTask();


    // We are processing one ICMPv6 packet at a time.
    // In addition, we can have one packet being processed
    // by a handler while we are computing the checksum
    // for another.


// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)



    command inline error_t Init.init()
    {
        // m_dispatchedPktPtr = NULL;
        // call PacketReadyBit.clear();
        return SUCCESS;
    }



    event error_t PacketReceiver.startReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        local_dbg("[ICMPv6] Attempting to start receiving an ICMPv6 "
            "message embedded in IPv6 packet %lu, which corresponds "
            "to incoming packet state %lu.\r\n",
            (long unsigned)inPacket->packet, (long unsigned)inPacket);

        if (call ProcessedPacketQueue.isFull())
        {
            local_dbg("[ICMPv6] No queue space to receive an ICMPv6 "
                "message embedded in IPv6 packet %lu, which corresponds "
                "to incoming packet state %lu.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket);

            return ENOMEM;
        }

        if (call ProcessedPacketQueue.isEmpty())
        {
            post startProcessingICMPv6MessageTask();
        }

        call ProcessedPacketQueue.enqueueLast(inPacket);

        local_dbg("[ICMPv6] Successfully started receiving an ICMPv6 "
            "message embedded in IPv6 packet %lu, which corresponds "
            "to incoming packet state %lu.\r\n",
            (long unsigned)inPacket->packet, (long unsigned)inPacket);

        return SUCCESS;
    }



    task void startProcessingICMPv6MessageTask()
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;
        whip6_ipv6_basic_header_t const *           ipv6Hdr;
        ipv6_payload_length_t                       msgLength;

        local_assert(! call ProcessedPacketQueue.isEmpty());

        inPacket = call ProcessedPacketQueue.peekFirst();
        ipv6Hdr = &inPacket->packet->header;
        msgLength =
                whip6_ipv6BasicHeaderGetPayloadLength(ipv6Hdr) -
                        inPacket->payloadOffset;

        if (call PacketReadyBit.isSet())
        {
            // There is a packet ready.

            local_assert(m_dispatchedPktPtr == NULL);

            call PacketReadyBit.clear();
            call ProcessedPacketQueue.dequeueFirst();
            if (! call ProcessedPacketQueue.isEmpty())
            {
                post startProcessingICMPv6MessageTask();
            }

            local_dbg("[ICMPv6] Passing the ICMPv6 message embedded in "
                "packet %lu, which corresponds to incoming packet state %lu, "
                "to the handler for type %u and code %u.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket,
                (unsigned)m_msgHeader.type, (unsigned)m_msgHeader.code);

            if (signal ICMPv6MessageReceiver.startReceivingMessage[m_msgHeader.type](
                        m_msgHeader.code,
                        &inPacket->payloadIter,
                        msgLength,
                        whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                        whip6_ipv6BasicHeaderGetDstAddrPtrForReading(ipv6Hdr)) == SUCCESS)
            {
                local_dbg("[ICMPv6] Successfully passed the ICMPv6 message embedded in "
                    "packet %lu, which corresponds to incoming packet state %lu, "
                    "to the handler for type %u and code %u.\r\n",
                    (long unsigned)inPacket->packet, (long unsigned)inPacket,
                    (unsigned)m_msgHeader.type, (unsigned)m_msgHeader.code);
            
                m_dispatchedPktPtr = inPacket;
            }
            else
            {
                local_dbg("[ICMPv6] Failed to pass the ICMPv6 message embedded in "
                    "packet %lu, which corresponds to incoming packet state %lu, "
                    "to the handler for type %u and code %u.\r\n",
                    (long unsigned)inPacket->packet, (long unsigned)inPacket,
                    (unsigned)m_msgHeader.type, (unsigned)m_msgHeader.code);
    
                finishProcessingIPv6Packet(inPacket, FAIL);
            }
        }
        else
        {
            // No packet is ready yet.

            whip6_iovIteratorClone(
                    &inPacket->payloadIter,
                    &m_msgChecksumIter
            );

            local_dbg("[ICMPv6] Reading the basic header of the ICMPv6 "
                "message embedded in IPv6 packet %lu, which corresponds "
                "to incoming packet state %lu.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket);

            if (whip6_iovIteratorReadAndMoveForward(
                        &inPacket->payloadIter,
                        (uint8_t_xdata *)&m_msgHeader,
                        sizeof(icmpv6_message_header_t)) != sizeof(icmpv6_message_header_t))
            {
                local_dbg("[ICMPv6] Failed to read the basic ICMPv6 header "
                    "from the message.\r\n");

                goto FAILURE_ROLLBACK_0;
            }
            inPacket->payloadOffset += sizeof(icmpv6_message_header_t);

            if (! signal ICMPv6MessageReceiver.isCodeSupported[m_msgHeader.type](m_msgHeader.code))
            {
                local_dbg("[ICMPv6] Type-%u ICMPv6 messages with code %u are "
                    "not supported.\r\n", (unsigned)m_msgHeader.type,
                    (unsigned)m_msgHeader.code);
    
                goto FAILURE_ROLLBACK_0;
            }

            local_dbg("[ICMPv6] Starting to compute the checksum of the ICMPv6 "
                "message of %lu bytes embedded in IPv6 packet %lu, which "
                "corresponds to incoming packet state %lu.\r\n",
                (long unsigned)msgLength, (long unsigned)inPacket->packet,
                (long unsigned)inPacket);

            whip6_ipv6ChecksumComputationInit(
                    &m_msgChecksumComp
            );
            whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
                    &m_msgChecksumComp,
                    whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                    whip6_ipv6BasicHeaderGetDstAddrPtrForReading(ipv6Hdr),
                    (uint32_t)msgLength,
                    WHIP6_IANA_IPV6_ICMP
            );
        
            if (call ChecksumComputer.startChecksumming(
                        &m_msgChecksumComp,
                        &m_msgChecksumIter,
                        (size_t)msgLength) != SUCCESS)
            {
                local_dbg("[ICMPv6] Failed to start ICMPv6 checksum computation.\r\n");
    
                goto FAILURE_ROLLBACK_0;
            }

            local_dbg("[ICMPv6] Successfully started computing the checksum of "
                "the ICMPv6 message embedded in IPv6 packet %lu, which "
                "corresponds to incoming packet state %lu.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket);

            return;

        FAILURE_ROLLBACK_0:
            finishProcessingFirstQueuedICMPv6Message(FAIL);
        }
    }



    event void ChecksumComputer.finishChecksumming(
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t checksummedBytes
    )
    {
        ipv6_checksum_t                             checksum;

        local_assert(! call ProcessedPacketQueue.isEmpty());
        local_assert(checksumPtr == &m_msgChecksumComp);
        local_assert(iovIter == &m_msgChecksumIter);

        local_dbg("[ICMPv6] Finished the checksum computation over a "
            "%u-byte ICMPv6 message embedded in packet %lu, which "
            "corresponds to incoming packet state %lu.\r\n",
            (unsigned)checksummedBytes,
            (long unsigned)((call ProcessedPacketQueue.peekFirst())->packet),
            (long unsigned)(call ProcessedPacketQueue.peekFirst()));

        checksum = whip6_ipv6ChecksumComputationFinalize(&m_msgChecksumComp);
        if (checksum != 0)
        {
            local_dbg("[ICMPv6] The checksum value is invalid, %u.\r\n",
                (unsigned)checksum);

            goto FAILURE_ROLLBACK_0;
        }
        call PacketReadyBit.set();
        if (m_dispatchedPktPtr == NULL)
        {
            local_dbg("[ICMPv6] No ICMPv6 message is currently being "
                "processed by a handler. Scheduling the processing of "
                "the message embedded in packet %lu, which corresponds to "
                "incoming packet state %lu.\r\n",
                (long unsigned)((call ProcessedPacketQueue.peekFirst())->packet),
                (long unsigned)(call ProcessedPacketQueue.peekFirst()));

            post startProcessingICMPv6MessageTask();
        }
        return;

    FAILURE_ROLLBACK_0:
        finishProcessingFirstQueuedICMPv6Message(FAIL);
    }



    void finishProcessingFirstQueuedICMPv6Message(error_t status)
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;

        local_assert(! call ProcessedPacketQueue.isEmpty());

        inPacket = call ProcessedPacketQueue.peekFirst();
        call ProcessedPacketQueue.dequeueFirst();
        if (! call ProcessedPacketQueue.isEmpty())
        {
            post startProcessingICMPv6MessageTask();
        }
        finishProcessingIPv6Packet(inPacket, status);
    }



    command void ICMPv6MessageReceiver.finishReceivingMessage[icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
        local_assert(m_dispatchedPktPtr != NULL);
        local_assert(&m_dispatchedPktPtr->payloadIter == payloadIter);

        local_dbg("[ICMPv6] The ICMPv6 message handler of type %u returned "
            "the message embedded in packet %lu, which corresponds to "
            "incoming packet state %lu, with status %u.\r\n",
            (unsigned)msgType, (long unsigned)m_dispatchedPktPtr->packet,
            (long unsigned)m_dispatchedPktPtr, (unsigned)status);

        finishProcessingIPv6Packet(m_dispatchedPktPtr, status);
        m_dispatchedPktPtr = NULL;
        if (call PacketReadyBit.isSet())
        {
            local_assert(! call ProcessedPacketQueue.isEmpty());
            
            post startProcessingICMPv6MessageTask();
        }
    }



    void finishProcessingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        local_dbg("[ICMPv6] Finishing handling with status %u an ICMPv6 "
            "message embedded in IPv6 packet %lu, which corresponds "
            "to incoming packet state %lu.\r\n", (unsigned)status,
            (long unsigned)inPacket->packet, (long unsigned)inPacket);

        whip6_iovIteratorInvalidate(&inPacket->payloadIter);
        inPacket->nextHeaderId = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
        call PacketReceiver.finishReceivingIPv6Packet(inPacket, status);
    }



    default event inline bool ICMPv6MessageReceiver.isCodeSupported[icmpv6_message_type_t msgType](
            icmpv6_message_code_t msgCode
    )
    {
        return FALSE;
    }



    default event inline error_t ICMPv6MessageReceiver.startReceivingMessage[icmpv6_message_type_t msgType](
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddr,
            whip6_ipv6_addr_t const * dstAddr
    )
    {
        return ENOSYS;
    }

#undef local_dbg
#undef local_assert
}

