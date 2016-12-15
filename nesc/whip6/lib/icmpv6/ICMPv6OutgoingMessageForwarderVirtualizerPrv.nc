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
#include <icmpv6/ucIcmpv6BasicMessageProcessing.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6Checksum.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * The module for forwarding outgoing ICMPv6
 * messages to the appropriate network interface.
 *
 * @param num_clients The number of clients for the
 *   forwarder. Must be at least 1.
 *
 * @author Konrad Iwanicki
 */
generic module ICMPv6OutgoingMessageForwarderVirtualizerPrv(
        uint8_t num_clients
)
{
    provides
    {
        interface Init @exactlyonce();
        interface ICMPv6MessageSender[uint8_t clientId, icmpv6_message_type_t msgType];
    }
    uses
    {
        interface IPv6PacketSourceAddressSelector as PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender as PacketSender @exactlyonce();
        interface IPv6ChecksumComputer as ChecksumComputer @exactlyonce();
        interface Queue<uint8_t, uint8_t> as ActiveClientQueue;
        interface Bit as PacketReadyBit @exactlyonce();
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = num_clients,
    };

    typedef struct client_state_s
    {
        whip6_iov_blist_iter_t *        payloadIter;
        size_t                          payloadLen;
        icmpv6_message_header_t         icmpv6Hdr;
        whip6_ipv6_addr_t const *       srcAddrOrNull;
        whip6_ipv6_addr_t const *       dstAddr;
    } client_state_t;

    typedef client_state_t client_state_t_xdata; typedef client_state_t_xdata whip6_client_state_t;


    whip6_client_state_t                       m_clientData[NUM_CLIENTS];
    whip6_ipv6_out_packet_processing_state_t   m_ipv6State;
    whip6_iov_blist_t                          m_hdrIov;
    whip6_iov_blist_t                          m_payloadIov;
    whip6_iov_blist_iter_t                     m_payloadIter;
    whip6_ipv6_checksum_computation_t          m_checksumComp;
    error_t                                    m_handlingStatus;

    error_t initChecksumComputation();
    void finishProcessingPacket(whip6_client_state_t * clientPtr);
    void finishHandlingFirstClient(error_t status);
    task void handleClientTask();


    // Only one packet is processed at a time.


// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)

#define LOCAL_FATAL_FAILURE

    command inline error_t Init.init()
    {
        // uint8_t clientIdx;
        // for (clientIdx = 0; clientIdx < NUM_CLIENTS; ++clientIdx)
        // {
        //     m_clientData[clientIdx].payloadIter = NULL;
        // }
        // m_clientIdx = 0;
        return SUCCESS;
    }



    command error_t ICMPv6MessageSender.startSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddrOrNull,
            whip6_ipv6_addr_t const * dstAddr
    )
    {
        whip6_client_state_t *   clientPtr;
        error_t                  status;

        local_assert(clientId < NUM_CLIENTS);
        local_assert(payloadIter != NULL);
        local_assert(dstAddr != NULL);

        local_dbg("[ICMPv6] Queueing a %u-byte ICMPv6 message of type %u "
            "with code %u pointed to by iterator %lu for sending.\r\n",
            (unsigned)payloadLen, (unsigned)msgType, (unsigned)msgCode,
            (long unsigned)payloadIter);

        if (call ActiveClientQueue.isFull())
        {
            local_dbg("[ICMPv6] No queue space to send the message.\r\n");

            status = ENOMEM;
            goto FAILURE_ROLLBACK_0;
        }
        clientPtr = &(m_clientData[clientId]);
        if (clientPtr->payloadIter != NULL)
        {
            local_dbg("[ICMPv6] ICMPv6 client %u is busy sending another "
                "message pointed by iterator %lu.\r\n", (unsigned)clientId,
                (long unsigned)clientPtr->payloadIter);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        clientPtr->payloadIter = payloadIter;
        clientPtr->payloadLen = payloadLen;
        clientPtr->icmpv6Hdr.type = msgType;
        clientPtr->icmpv6Hdr.code = msgCode;
        clientPtr->icmpv6Hdr.checksum[0] = 0;
        clientPtr->icmpv6Hdr.checksum[1] = 0;
        clientPtr->srcAddrOrNull = srcAddrOrNull;
        clientPtr->dstAddr = dstAddr;
        if (call ActiveClientQueue.isEmpty())
        {
            post handleClientTask();
        }
        call ActiveClientQueue.enqueueLast(clientId);

        local_dbg("[ICMPv6] Queued a %u-byte ICMPv6 message of type %u "
            "with code %u pointed to by iterator %lu for sending.\r\n",
            (unsigned)payloadLen, (unsigned)msgType, (unsigned)msgCode,
            (long unsigned)payloadIter);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void handleClientTask()
    {
        whip6_client_state_t *     clientPtr;
        uint8_t                    clientId;
        error_t                    status;

        local_assert(! call ActiveClientQueue.isEmpty());

        clientId = call ActiveClientQueue.peekFirst();
        clientPtr = &(m_clientData[clientId]);

        if (m_ipv6State.packet == NULL)
        {
            // Start handling client.
        
            local_dbg("[ICMPv6] Creating an IPv6 packet that will hold the "
                "ICMPv6 message pointed by I/O vector iterator %lu.\r\n",
                (long unsigned)clientPtr->payloadIter);

            m_ipv6State.packet =
                    whip6_icmpv6WrapDataIntoOutgoingIpv6PacketCarryingIcmpMessage(
                            clientPtr->payloadIter,
                            clientPtr->payloadLen,
                            &clientPtr->icmpv6Hdr,
                            &m_hdrIov,
                            &m_payloadIov,
                            clientPtr->srcAddrOrNull,
                            clientPtr->dstAddr
                    );
            if (m_ipv6State.packet == NULL)
            {
                local_dbg("[ICMPv6] Failed to create an IPv6 packet for the "
                    "ICMPv6 message pointed by I/O vector iterator %lu.\r\n",
                    (long unsigned)clientPtr->payloadIter);

                status = ENOMEM;
                goto HANDLING_FINISH_0;
            }

            local_dbg("[ICMPv6] Created an IPv6 packet, %lu, which corresponds "
                "to outgoing packet state %lu and which holds the "
                "ICMPv6 message pointed by I/O vector iterator %lu.\r\n",
                (long unsigned)m_ipv6State.packet, (long unsigned)&m_ipv6State,
                (long unsigned)clientPtr->payloadIter);

            m_ipv6State.flags =
                    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING;
            if (whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&m_ipv6State.packet->header)))
            {
                local_dbg("[ICMPv6] Initiating source address selection "
                    "for the IPv6 packet.\r\n");

                status =
                        call PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
                                &m_ipv6State
                        );
                if (status != SUCCESS)
                {
                    local_dbg("[ICMPv6] Failed to initiate source address "
                        "selection for the IPv6 packet.\r\n");

                    goto HANDLING_FINISH_1;
                }
            }
            else
            {
                local_dbg("[ICMPv6] Initiating ICMPv6 checksum computation "
                    "for the IPv6 packet.\r\n");

                m_ipv6State.flags |=
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS;
                if (initChecksumComputation() != SUCCESS)
                {
                    local_dbg("[ICMPv6] Failed to initiate ICMPv6 checksum "
                        "computation for the IPv6 packet.\r\n");

                    status = FAIL;
                    goto HANDLING_FINISH_1;
                }
            }
        }
        else
        {
            // Finish handling client.
            
            local_dbg("[ICMPv6] Finishing handling the ICMPv6 message "
                "pointed by I/O vector iterator %lu with status %u.\r\n",
                (long unsigned)clientPtr->payloadIter,
                (unsigned)m_handlingStatus);

            status = m_handlingStatus;
            goto HANDLING_FINISH_1;
        }
        return;

    HANDLING_FINISH_1:
        finishProcessingPacket(clientPtr);
    HANDLING_FINISH_0:
        finishHandlingFirstClient(status);
    }



    event void PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        local_assert(m_ipv6State.packet != NULL);
        local_assert(outPacket == &m_ipv6State);
        local_assert(! call ActiveClientQueue.isEmpty());

        call ActiveClientQueue.peekFirst();

        local_dbg("[ICMPv6] Source address selection for IPv6 packet %lu, "
            "which corresponds to outgoing packet state %lu, has finished "
            "with status %u.\r\n", (long unsigned)outPacket->packet,
            (long unsigned)outPacket, (unsigned)status);

        if (status != SUCCESS)
        {
            local_dbg("[ICMPv6] The source address selection has failed.\r\n");
            
            m_handlingStatus = status;
            goto FAILURE_ROLLBACK_0;
        }
        
        local_dbg("[ICMPv6] The source address selection succeeded. "
            "Initializing checksum computation for the packet.\r\n");
        
        if (initChecksumComputation() != SUCCESS)
        {
            local_dbg("[ICMPv6] Failed to initiate ICMPv6 checksum "
                "computation for the IPv6 packet.\r\n");
            
            m_handlingStatus = FAIL;
            goto FAILURE_ROLLBACK_0;
        }
        return;
        
    FAILURE_ROLLBACK_0:
        post handleClientTask();
    }



    error_t initChecksumComputation()
    {
        whip6_ipv6_basic_header_t const *   ipv6Hdr;
        ipv6_payload_length_t               msgLen;

        local_assert(m_ipv6State.packet != NULL);

        ipv6Hdr = &m_ipv6State.packet->header;
        msgLen = whip6_ipv6BasicHeaderGetPayloadLength(ipv6Hdr);
        whip6_ipv6ChecksumComputationInit(
                &m_checksumComp
        );
        whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
                &m_checksumComp,
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(ipv6Hdr),
                (uint32_t)msgLen,
                WHIP6_IANA_IPV6_ICMP
        );
        whip6_iovIteratorInitToBeginning(
                m_ipv6State.packet->firstPayloadIov,
                &m_payloadIter
        );
        return call ChecksumComputer.startChecksumming(
                &m_checksumComp,
                &m_payloadIter,
                (size_t)msgLen
        );
    }



    event void ChecksumComputer.finishChecksumming(
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t checksummedBytes
    )
    {
        ipv6_checksum_t            checksum;
        uint8_t                    clientId;
        whip6_client_state_t *     clientPtr;

        local_assert(! call ActiveClientQueue.isEmpty());
        local_assert(m_ipv6State.packet != NULL);
        local_assert(&m_checksumComp == checksumPtr);
        local_assert(&m_payloadIter == iovIter);
        local_assert(checksummedBytes == whip6_ipv6BasicHeaderGetPayloadLength(&m_ipv6State.packet->header));

        checksum = whip6_ipv6ChecksumComputationFinalize(&m_checksumComp);
        clientId = call ActiveClientQueue.peekFirst();
        clientPtr = &(m_clientData[clientId]);
        clientPtr->icmpv6Hdr.checksum[0] = (uint8_t)(checksum >> 8);
        clientPtr->icmpv6Hdr.checksum[1] = (uint8_t)(checksum);

        local_dbg("[ICMPv6] The checksum computation for the ICMPv6 message "
            "pointed by I/O vector iterator %lu and embedded in IPv6 "
            "packet %lu, which corresponds to outgoing packet state %lu, "
            "has finished. Initiating routing of the packet.\r\n",
            (long unsigned)clientPtr->payloadIter,
            (long unsigned)m_ipv6State.packet, (long unsigned)&m_ipv6State);

        m_handlingStatus = call PacketSender.startSendingIPv6Packet(&m_ipv6State);
        if (m_handlingStatus != SUCCESS)
        {
            local_dbg("[ICMPv6] Failed to initiate the routing of the packet.\r\n");
            
            post handleClientTask();
        }
    }



    event inline void PacketSender.finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        local_assert(! call ActiveClientQueue.isEmpty());
        local_assert(m_ipv6State.packet != NULL);
        local_assert(&m_ipv6State == outPacket);

        local_dbg("[ICMPv6] Finished routing the ICMPv6 message "
            "pointed by I/O vector iterator %lu and embedded in IPv6 "
            "packet %lu, which corresponds to outgoing packet state %lu, "
            "with status %u.\r\n",
            (long unsigned)m_clientData[call ActiveClientQueue.peekFirst()].payloadIter,
            (long unsigned)m_ipv6State.packet, (long unsigned)&m_ipv6State,
            (unsigned)status);

        m_handlingStatus = status;
        post handleClientTask();
    }



    void finishProcessingPacket(whip6_client_state_t * clientPtr)
    {
        local_assert(m_ipv6State.packet != NULL);

        local_dbg("[ICMPv6] Destroying the IPv6 packet, %lu, that holds the "
            "ICMPv6 message pointed by I/O vector iterator %lu.\r\n",
            (long unsigned)m_ipv6State.packet,
            (long unsigned)clientPtr->payloadIter);

        if (whip6_icmpv6UnwrapDataFromOutgoingIpv6PacketCarryingIcmpMessage(
                    m_ipv6State.packet,
                    clientPtr->payloadIter,
                    clientPtr->payloadLen,
                    &m_hdrIov,
                    &m_payloadIov))
        {
            LOCAL_FATAL_FAILURE;
        }
        m_ipv6State.packet = NULL;
    }



    void finishHandlingFirstClient(error_t status)
    {
        whip6_client_state_t *     clientPtr;
        whip6_iov_blist_iter_t *   payloadIter;
        uint8_t                    clientId;

        local_assert(! call ActiveClientQueue.isEmpty());

        clientId = call ActiveClientQueue.peekFirst();
        call ActiveClientQueue.dequeueFirst();
        if (! call ActiveClientQueue.isEmpty())
        {
            post handleClientTask();
        }
        clientPtr = &(m_clientData[clientId]);

        local_dbg("[ICMPv6] Finishing sending a %u-byte ICMPv6 message "
            "of type %u with code %u pointed to by iterator %lu.\r\n",
            (unsigned)clientPtr->payloadLen,
            (unsigned)clientPtr->icmpv6Hdr.type,
            (unsigned)clientPtr->icmpv6Hdr.code,
            (long unsigned)clientPtr->payloadIter);

        payloadIter = clientPtr->payloadIter;
        clientPtr->payloadIter = NULL;
        signal ICMPv6MessageSender.finishSendingMessage[clientId, clientPtr->icmpv6Hdr.type](payloadIter, status);
    }



    command error_t ICMPv6MessageSender.stopSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter
    )
    {
        whip6_client_state_t *   clientPtr;
        uint8_t                  i, n;

        local_assert(clientId < NUM_CLIENTS);
        local_assert(payloadIter != NULL);

        local_dbg("[ICMPv6] Trying to stop sending an ICMPv6 message "
            "of type %u pointed to by I/O vector iterator %lu.\r\n",
            (unsigned)msgType, (long unsigned)payloadIter);

        clientPtr = &(m_clientData[clientId]);
        if (clientPtr->payloadIter != payloadIter)
        {
            local_dbg("[ICMPv6] The iterator is invalid.\r\n");

            return EINVAL;
        }
        if (clientPtr->icmpv6Hdr.type != msgType)
        {
            local_dbg("[ICMPv6] The type is incompatible.\r\n");

            return EINVAL;
        }
        
        local_assert(! call ActiveClientQueue.isEmpty());
        
        // NOTICE iwanicki 2014-01-06:
        // To cancel this client, we would have to track
        // what is going on with the packet. Since we are
        // not doing this, we do not allow for canceling
        // the first client in the queue.
        if (call ActiveClientQueue.peekFirst() == clientId)
        {
            local_dbg("[ICMPv6] Unable to cancel the message now.\r\n");

            return EBUSY;
        }
        for (i = 1, n = call ActiveClientQueue.getSize(); i < n; ++i)
        {
            if (call ActiveClientQueue.peekIth(i) == clientId)
            {
                local_dbg("[ICMPv6] Successfully stopped sending an ICMPv6 "
                    "message of type %u pointed to by I/O vector "
                    "iterator %lu.\r\n", (unsigned)msgType,
                    (long unsigned)payloadIter);

                call ActiveClientQueue.dequeueIth(i);
                return SUCCESS;
            }
        }
        return ESTATE;
    }
    
    
    
    default event inline void ICMPv6MessageSender.finishSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
        LOCAL_FATAL_FAILURE;
    }

#undef local_dbg
#undef local_assert
#undef LOCAL_FATAL_FAILURE
}

