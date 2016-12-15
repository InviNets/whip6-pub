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
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6Checksum.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>
#include <udp/ucUdpHeaderManipulation.h>
#include <udp/ucUdpBasicTypes.h>


// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)
#define LOCAL_FATAL_FAILURE

/**
 * The main module of a manager for raw UDP sockets.
 *
 * @param num_sockets The number of sockets.
 * @param max_bytes_processed_per_task The maximal
 *   number of bytes processed in a single task.
 *
 * @author Konrad Iwanicki
 */
generic module UDPRawSocketManagerMainPrv(
        udp_socket_id_t num_sockets,
        size_t max_bytes_processed_per_task
)
{
    provides
    {
        interface Init;
        interface UDPSocketController[udp_socket_id_t sockId];        
        interface UDPRawReceiver[udp_socket_id_t sockId];
        interface UDPRawSender[udp_socket_id_t sockId];
    }
    uses
    {
        interface IPv6PacketReceiver @exactlyonce();
        interface IPv6PacketSender @exactlyonce();
        interface IPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6InterfaceStateProvider[ipv6_net_iface_id_t ifaceId];
        interface Random @exactlyonce();
    }
}
implementation
{
    enum
    {
        NUM_SOCKETS = num_sockets,
    };

    enum
    {
        MAX_BYTES_PROCESSED_PER_TASK = max_bytes_processed_per_task,
    };

    enum
    {
        MAX_PORT_GENERATION_ATTEMPTS = 4 * NUM_SOCKETS,
    };

    enum
    {
        MAX_UDP_PAYLOAD = WHIP6_IPV6_MIN_MTU - sizeof(udp_header_t),
    };

    enum
    {
        MIN_RANDOM_PORT_NO = 49152U,
        MAX_RANDOM_PORT_NO = 65535U,
    };

    enum
    {
        OUT_ACTION_WAITING_FOR_SOMETHING = 0,
        OUT_ACTION_START_HANDLING_PACKET = 1,
        OUT_ACTION_START_COMPUTING_CHECKSUM = 2,
        OUT_ACTION_CONTINUE_COMPUTING_CHECKSUM = 3,
        OUT_ACTION_START_ROUTING_PACKET = 4,
        OUT_ACTION_COMPLETE_HANDLING_PACKET = 5,
        OUT_ACTION_TERMINATE_HANDLING_PACKET = 6,
    };

    typedef struct out_state_s
    {
        ipv6_out_packet_processing_state_t          ipv6State;
        iov_blist_t                                 udpIov;
        udp_header_t                                udpHeader;
        ipv6_checksum_computation_t                 csComp;
        iov_blist_iter_t                            iovIter;
        size_t                                      iovProcessed;
        size_t                                      iovTotal;
        uint8_t                                     action;
    } out_state_t;

    typedef struct in_state_s
    {
        whip6_ipv6_in_packet_processing_state_t *   ipv6StatePtr;
        iov_blist_t                                 iovHead;
        ipv6_checksum_computation_t                 csComp;
        ipv6_checksum_t                             csValue;
        iov_blist_iter_t                            iovIter;
        size_t                                      iovProcessed;
        size_t                                      iovTotal;
        udp_socket_addr_t                           srcSockAddr;
    } in_state_t;

    typedef struct udp_raw_socket_s
    {
        udp_socket_addr_t                           localAddr;
        udp_socket_addr_t                           remoteAddr;
        out_state_t                                 out;
        in_state_t                                  in;
    } udp_raw_socket_t;

    typedef udp_raw_socket_t udp_raw_socket_t_xdata; typedef udp_raw_socket_t_xdata whip6_udp_raw_socket_t;


    whip6_udp_raw_socket_t   m_sockets[NUM_SOCKETS];
    udp_socket_id_t          m_currInSock = 0;
    udp_socket_id_t          m_currOutSock = 0;
    whip6_udp_header_t       m_tmpUdpHeader;



    static bool isBound(
            whip6_udp_raw_socket_t const * socketPtr
    );
    static bool isConnected(
            whip6_udp_raw_socket_t const * socketPtr
    );
    static bool isLocalAddressValid(
            whip6_ipv6_addr_t const * ipv6Addr
    );
    static udp_port_no_t generateFreePortNo();
    static udp_socket_id_t findSocketForPortNo(
            udp_port_no_t portNo
    );
    static udp_socket_id_t findSocketForOutIpv6State(
            whip6_ipv6_out_packet_processing_state_t const * outIpv6State
    );
    static bool startAddressSelectionForOutPacketIfNecessary(
            whip6_udp_raw_socket_t * socketPtr
    );
    static void initChecksumComputationForOutPacket(
            whip6_udp_raw_socket_t * socketPtr
    );
    static bool contChecksumComputationForOutPacket(
            whip6_udp_raw_socket_t * socketPtr
    );
    static void startPacketRoutingForOutPacket(
            whip6_udp_raw_socket_t * socketPtr
    );
    static void finishHandlingOutPacket(
            udp_socket_id_t sockId, error_t status
    );
    static error_t initChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr
    );
    static error_t contChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr,
            size_t numRequested
    );
    static error_t endChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr,
            udp_socket_id_t sockId
    );
    static void finishHandlingInPacket(
            udp_socket_id_t sockId, error_t status
    );

    task void handleOutgoingPacketTask();
    task void handleIncomingPacketTask();




    // *********************************************************************
    // *                                                                   *
    // *                     Initialization & Control                      *
    // *                                                                   *
    // *********************************************************************

    command error_t Init.init()
    {
        whip6_udp_raw_socket_t *   socketPtr;
        udp_socket_id_t            sockId;

        socketPtr = &(m_sockets[0]);
        for (sockId = NUM_SOCKETS; sockId > 0; --sockId)
        {
            socketPtr->localAddr.udpPortNo = 0;
            socketPtr->remoteAddr.udpPortNo = 0;
            socketPtr->out.ipv6State.packet = NULL;
            socketPtr->in.ipv6StatePtr = NULL;
            ++socketPtr;
        }
        return SUCCESS;
    }



    static inline bool isBound(whip6_udp_raw_socket_t const * socketPtr)
    {
        return socketPtr->localAddr.udpPortNo != 0;
    }



    static inline bool isConnected(whip6_udp_raw_socket_t const * socketPtr)
    {
        return socketPtr->remoteAddr.udpPortNo != 0;
    }



    command inline error_t UDPSocketController.bind[udp_socket_id_t sockId](
            whip6_udp_socket_addr_t const * sockAddr
    )
    {
        return call UDPSocketController.bindToAddrAndPort[sockId](
                &sockAddr->ipv6Addr,
                sockAddr->udpPortNo
        );
    }



    command error_t UDPSocketController.bindToAddrAndPort[udp_socket_id_t sockId](
            whip6_ipv6_addr_t const * ipv6Addr,
            udp_port_no_t udpPortNo
    )
    {
        whip6_udp_raw_socket_t *   socketPtr;

        // ASSUMPTION: sockId < NUM_SOCKETS
        socketPtr = &(m_sockets[sockId]);
        if (isBound(socketPtr))
        {
            return EALREADY;
        }
        if (! isLocalAddressValid(ipv6Addr))
        {
            return EINVAL;
        }
        if (udpPortNo == 0)
        {
            udpPortNo = generateFreePortNo();
            if (udpPortNo == 0)
            {
                return ENOMEM;
            }
        }
        else if (findSocketForPortNo(udpPortNo) < NUM_SOCKETS)
        {
            return EBUSY;
        }
        whip6_shortMemCpy(
                (uint8_t_xdata const *)ipv6Addr,
                (uint8_t_xdata *)&socketPtr->localAddr.ipv6Addr,
                sizeof(whip6_ipv6_addr_t)
        );
        socketPtr->localAddr.udpPortNo = udpPortNo;
        return SUCCESS;
    }



    static bool isLocalAddressValid(whip6_ipv6_addr_t const * ipv6Addr)
    {
        whip6_ipv6_net_iface_generic_state_t const *  ifaceState;
        ipv6_net_iface_id_t                           ifaceId;

        if (whip6_ipv6AddrIsUndefined(ipv6Addr))
        {
            return TRUE;
        }
        ifaceId = 0;
        do
        {
            ifaceState = call IPv6InterfaceStateProvider.getInterfaceStatePtr[ifaceId]();
            if (ifaceState == NULL)
            {
                return FALSE;
            }
            if (whip6_ipv6AddrBelongsToInterface(ifaceState, ipv6Addr))
            {
                return TRUE;
            }
            ++ifaceId;
        }
        while (TRUE);
    }



    static udp_port_no_t generateFreePortNo()
    {
        udp_port_no_t              portNo;
        udp_socket_id_t            attemptsLeft;

        for (attemptsLeft = MAX_PORT_GENERATION_ATTEMPTS; attemptsLeft > 0; --attemptsLeft)
        {
            portNo =
                    (udp_port_no_t)(
                            call Random.rand16() %
                                    (MAX_RANDOM_PORT_NO - MIN_RANDOM_PORT_NO) +
                                            MIN_RANDOM_PORT_NO);
            if (findSocketForPortNo(portNo) >= NUM_SOCKETS)
            {
                return portNo;
            }
        }
        return (udp_port_no_t)0;
    }



    static udp_socket_id_t findSocketForPortNo(udp_port_no_t portNo)
    {
        whip6_udp_raw_socket_t const *   socketPtr;
        udp_socket_id_t                  sockId;

        socketPtr = &(m_sockets[0]);
        for (sockId = 0; sockId < NUM_SOCKETS; ++sockId)
        {
            if (socketPtr->localAddr.udpPortNo == portNo)
            {
                return sockId;
            }
            ++socketPtr;
        }
        return NUM_SOCKETS;
    }



    command inline error_t UDPSocketController.connect[udp_socket_id_t sockId](
            whip6_udp_socket_addr_t const * sockAddr
    )
    {
        return call UDPSocketController.connectToAddrAndPort[sockId](
                &sockAddr->ipv6Addr,
                sockAddr->udpPortNo
        );
    }



    command error_t UDPSocketController.connectToAddrAndPort[udp_socket_id_t sockId](
            whip6_ipv6_addr_t const * ipv6Addr,
            udp_port_no_t udpPortNo
    )
    {
        whip6_udp_raw_socket_t *   socketPtr;

        // ASSUMPTION: sockId < NUM_SOCKETS
        socketPtr = &(m_sockets[sockId]);
        if (! isBound(socketPtr))
        {
            return ESTATE;
        }
        if (udpPortNo == 0 || whip6_ipv6AddrIsUndefined(ipv6Addr))
        {
            return EINVAL;
        }
        whip6_shortMemCpy(
                (uint8_t_xdata const *)ipv6Addr,
                (uint8_t_xdata *)&socketPtr->remoteAddr.ipv6Addr,
                sizeof(whip6_ipv6_addr_t)
        );
        socketPtr->remoteAddr.udpPortNo = udpPortNo;
        return SUCCESS;
    }



    command inline whip6_udp_socket_addr_t const * UDPSocketController.getLocalAddr[udp_socket_id_t sockId]()
    {
        // ASSUMPTION: sockId < NUM_SOCKETS
        return &(m_sockets[sockId].localAddr);
    }



    command inline whip6_udp_socket_addr_t const * UDPSocketController.getRemoteAddr[udp_socket_id_t sockId]()
    {
        // ASSUMPTION: sockId < NUM_SOCKETS
        return &(m_sockets[sockId].remoteAddr);
    }



    command inline bool UDPSocketController.isBound[udp_socket_id_t sockId]()
    {
        // ASSUMPTION: sockId < NUM_SOCKETS
        return isBound(&(m_sockets[sockId]));
    }



    command inline bool UDPSocketController.isConnected[udp_socket_id_t sockId]()
    {
        // ASSUMPTION: sockId < NUM_SOCKETS
        return isConnected(&(m_sockets[sockId]));
    }



    // *********************************************************************
    // *                                                                   *
    // *                              Sending                              *
    // *                                                                   *
    // *********************************************************************

    command error_t UDPRawSender.startSending[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * dstSockAddrOrNull
    )
    {
        whip6_udp_raw_socket_t *      socketPtr;
        error_t                       status;

        local_dbg("[RawSocket:%u] Attempting to start sending I/O vector %lu "
                "of %lu bytes.\r\n", (unsigned)sockId, (long unsigned)payloadIov,
                (long unsigned)payloadSize);

        // ASSUMPTION: sockId < NUM_SOCKETS
        socketPtr = &(m_sockets[sockId]);
        if (! isBound(socketPtr))
        {
            local_dbg("[RawSocket:%u] Sending I/O vector %lu failed, because "
                    "the socket is not bound.\r\n", (unsigned)sockId,
                    (long unsigned)payloadIov);

            status = ESTATE;
            goto FAILURE_ROLLBACK_0;
        }
        if (payloadSize > MAX_UDP_PAYLOAD)
        {
            local_dbg("[RawSocket:%u] Sending I/O vector %lu failed, because "
                    "the payload is too large.\r\n", (unsigned)sockId,
                    (long unsigned)payloadIov);

            status = ESIZE;
            goto FAILURE_ROLLBACK_0;
        }
        if (dstSockAddrOrNull == NULL)
        {
            if (! isConnected(socketPtr))
            {
                local_dbg("[RawSocket:%u] Sending I/O vector %lu failed, because "
                        "the socket is not connected.\r\n", (unsigned)sockId,
                        (long unsigned)payloadIov);

                status = EINVAL;
                goto FAILURE_ROLLBACK_0;
            }
            dstSockAddrOrNull = &socketPtr->remoteAddr;
        }
        if (socketPtr->out.ipv6State.packet != NULL)
        {
            local_dbg("[RawSocket:%u] Sending I/O vector %lu failed, because "
                    "the socket is busy.\r\n", (unsigned)sockId,
                    (long unsigned)payloadIov);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr->out.udpIov.iov.ptr = (uint8_t_xdata *)&socketPtr->out.udpHeader;
        socketPtr->out.udpIov.iov.len = sizeof(udp_header_t);
        socketPtr->out.ipv6State.packet =
                whip6_udpWrapDataIntoOutgoingIpv6PacketCarryingUdpDatagram(
                        payloadIov,
                        payloadSize,
                        &socketPtr->out.udpIov,
                        &socketPtr->localAddr,
                        dstSockAddrOrNull                        
                );
        if (socketPtr->out.ipv6State.packet == NULL)
        {
            local_dbg("[RawSocket:%u] Sending I/O vector %lu failed, because "
                    "it was impossible to wrap the I/O vector into an "
                    "IPv6 packet with a UDP datagram.\r\n", (unsigned)sockId,
                    (long unsigned)payloadIov);

            status = FAIL;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr->out.action = OUT_ACTION_START_HANDLING_PACKET;
        post handleOutgoingPacketTask();

        local_dbg("[RawSocket:%u] Successfully started sending I/O "
                "vector %lu of %lu bytes.\r\n", (unsigned)sockId,
                (long unsigned)payloadIov, (long unsigned)payloadSize);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void handleOutgoingPacketTask()
    {
        whip6_udp_raw_socket_t *      socketPtr;
        udp_socket_id_t               sockId;
        udp_socket_id_t               nextSockId;

        sockId = m_currOutSock;
        do
        {
            nextSockId = sockId + 1;
            if (nextSockId >= NUM_SOCKETS)
            {
                nextSockId = 0;
            }
            socketPtr = &(m_sockets[sockId]);
            if (socketPtr->out.action != OUT_ACTION_WAITING_FOR_SOMETHING &&
                    socketPtr->out.ipv6State.packet != NULL)
            {
                local_dbg("[RawSocket:%u] Performing socket action %d\r\n",
                          (unsigned)sockId, (int)socketPtr->out.action);
                switch (socketPtr->out.action)
                {
                case OUT_ACTION_START_HANDLING_PACKET:
                    if (startAddressSelectionForOutPacketIfNecessary(socketPtr))
                    {
                        break;
                    }
                case OUT_ACTION_START_COMPUTING_CHECKSUM:
                    initChecksumComputationForOutPacket(socketPtr);
                    break;
                case OUT_ACTION_CONTINUE_COMPUTING_CHECKSUM:
                    if (contChecksumComputationForOutPacket(socketPtr))
                    {
                        break;
                    }
                case OUT_ACTION_START_ROUTING_PACKET:
                    startPacketRoutingForOutPacket(socketPtr);
                    break;
                case OUT_ACTION_COMPLETE_HANDLING_PACKET:
                    finishHandlingOutPacket(sockId, SUCCESS);
                    break;
                case OUT_ACTION_TERMINATE_HANDLING_PACKET:
                    finishHandlingOutPacket(sockId, FAIL);
                    break;
                default:
                    LOCAL_FATAL_FAILURE;
                }

                m_currOutSock = nextSockId;
                post handleOutgoingPacketTask();
            }
            sockId = nextSockId;
        }
        while (sockId != m_currOutSock);
    }



    static bool startAddressSelectionForOutPacketIfNecessary(
            whip6_udp_raw_socket_t * socketPtr
    )
    {
        socketPtr->out.ipv6State.flags =
                WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING;
        if (! whip6_ipv6AddrIsUndefined(
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                        &socketPtr->out.ipv6State.packet->header)))
        {
            socketPtr->out.ipv6State.flags |=
                    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS;
            socketPtr->out.action = OUT_ACTION_START_COMPUTING_CHECKSUM;
            return FALSE;
        }
        else
        {
            if (call IPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
                    &socketPtr->out.ipv6State) == SUCCESS)
            {
                socketPtr->out.action = OUT_ACTION_WAITING_FOR_SOMETHING;
            }
            else
            {
                socketPtr->out.action = OUT_ACTION_TERMINATE_HANDLING_PACKET;
            }
            return TRUE;
        }
    }



    event void IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        whip6_udp_raw_socket_t *      socketPtr;
        udp_socket_id_t               sockId;

        // NOTICE iwanicki 2013-12-15:
        // We could actually compute the socket address
        // based on the outPacket address, but the search
        // method is more robust.
        sockId = findSocketForOutIpv6State(outPacket);
        if (sockId >= NUM_SOCKETS)
        {
            return;
        }
        socketPtr = &(m_sockets[sockId]);

        local_dbg("[RawSocket:%u] Source address selection for packet %lu, "
                "which corresponds to outgoing packet state %lu, has been "
                "finished with status %u by the lower layer.\r\n",
                (unsigned)sockId, (long unsigned)outPacket->packet,
                (long unsigned)outPacket, (unsigned)status);

        if (status == SUCCESS)
        {
            socketPtr->out.ipv6State.flags |=
                    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS;
            socketPtr->out.action = OUT_ACTION_START_COMPUTING_CHECKSUM;
        }
        else
        {
            socketPtr->out.action = OUT_ACTION_TERMINATE_HANDLING_PACKET;
        }
        post handleOutgoingPacketTask();
    }



    static udp_socket_id_t findSocketForOutIpv6State(
            whip6_ipv6_out_packet_processing_state_t const * outIpv6State
    )
    {
        whip6_udp_raw_socket_t const *   socketPtr;
        udp_socket_id_t                  sockId;

        socketPtr = &(m_sockets[0]);
        for (sockId = 0; sockId < NUM_SOCKETS; ++sockId)
        {
            if (&socketPtr->out.ipv6State == outIpv6State)
            {
                return sockId;
            }
            ++socketPtr;
        }
        return NUM_SOCKETS;
    }



    static void initChecksumComputationForOutPacket(whip6_udp_raw_socket_t * socketPtr)
    {
        whip6_ipv6_basic_header_t const *   ipv6Hdr;
        size_t                              payloadLen;

        ipv6Hdr = &socketPtr->out.ipv6State.packet->header;
        payloadLen = whip6_ipv6BasicHeaderGetPayloadLength(ipv6Hdr);
        whip6_ipv6ChecksumComputationInit(
                &socketPtr->out.csComp
        );
        whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
                &socketPtr->out.csComp,
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(ipv6Hdr),
                payloadLen,
                WHIP6_IANA_IPV6_UDP
        );
        whip6_iovIteratorInitToBeginning(
                socketPtr->out.ipv6State.packet->firstPayloadIov,
                &socketPtr->out.iovIter
        );
        socketPtr->out.iovProcessed = 0;
        socketPtr->out.iovTotal = payloadLen;
        socketPtr->out.action = OUT_ACTION_CONTINUE_COMPUTING_CHECKSUM;
    }



    static bool contChecksumComputationForOutPacket(
            whip6_udp_raw_socket_t * socketPtr
    )
    {
        if (socketPtr->out.iovProcessed >= socketPtr->out.iovTotal)
        {
            ipv6_checksum_t   checksum;

            checksum =
                    whip6_ipv6ChecksumComputationFinalize(
                            &socketPtr->out.csComp
                    );
            // RFC768, Page 2:
            // "If the computed  checksum  is zero,  it is transmitted  as all ones..."
            if (checksum == 0)
                checksum = 0xFFFF;
            whip6_udpHeaderSetChecksum(&socketPtr->out.udpHeader, checksum);
            socketPtr->out.action = OUT_ACTION_START_ROUTING_PACKET;
            return FALSE;
        }
        else
        {
            size_t   numBytes = socketPtr->out.iovTotal - socketPtr->out.iovProcessed;
            size_t   actBytes;

            if (numBytes > MAX_BYTES_PROCESSED_PER_TASK)
            {
                numBytes = MAX_BYTES_PROCESSED_PER_TASK;
            }
            actBytes =
                    whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                            &socketPtr->out.csComp,
                            &socketPtr->out.iovIter,
                            numBytes
                    );
            if (actBytes != numBytes)
            {
                socketPtr->out.action = OUT_ACTION_TERMINATE_HANDLING_PACKET;
            }
            else
            {
                socketPtr->out.iovProcessed += numBytes;
            }
            return TRUE;
        }
    }



    static void startPacketRoutingForOutPacket(
            whip6_udp_raw_socket_t * socketPtr
    )
    {
        if (call IPv6PacketSender.startSendingIPv6Packet(
                &socketPtr->out.ipv6State) == SUCCESS)
        {
            local_dbg("[RawSocket:%u] startSendingIPv6Packet SUCCESS\r\n");
            socketPtr->out.action = OUT_ACTION_WAITING_FOR_SOMETHING;
        }
        else
        {
            local_dbg("[RawSocket:%u] startSendingIPv6Packet FAIL\r\n");
            socketPtr->out.action = OUT_ACTION_TERMINATE_HANDLING_PACKET;
        }
    }



    event void IPv6PacketSender.finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        whip6_udp_raw_socket_t *      socketPtr;
        udp_socket_id_t               sockId;

        // NOTICE iwanicki 2013-12-15:
        // We could actually compute the socket address
        // based on the outPacket address, but the search
        // method is more robust.
        sockId = findSocketForOutIpv6State(outPacket);
        if (sockId >= NUM_SOCKETS)
        {
            return;
        }
        socketPtr = &(m_sockets[sockId]);

        local_dbg("[RawSocket:%u] Sending packet %lu, which corresponds "
                "to outgoing packet state %lu, has been finished with "
                "status %u by the lower layer.\r\n", (unsigned)sockId,
                (long unsigned)outPacket->packet, (long unsigned)outPacket,
                (unsigned)status);

        if (status == SUCCESS)
        {
            socketPtr->out.action = OUT_ACTION_COMPLETE_HANDLING_PACKET;
        }
        else
        {
            socketPtr->out.action = OUT_ACTION_TERMINATE_HANDLING_PACKET;
        }
        post handleOutgoingPacketTask();
    }



    static void finishHandlingOutPacket(
            udp_socket_id_t sockId,
            error_t status
    )
    {
        whip6_iov_blist_t *           payloadIov;
        size_t                        payloadSize;
        whip6_udp_raw_socket_t *      socketPtr;
        
        socketPtr = &(m_sockets[sockId]);
        if (whip6_udpUnwrapDataFromOutgoingIpv6PacketCarryingUdpDatagram(
                socketPtr->out.ipv6State.packet,
                &socketPtr->out.udpIov,
                &payloadIov,
                &payloadSize))
        {
            LOCAL_FATAL_FAILURE;
            return;
        }
        socketPtr->out.ipv6State.packet = NULL;

        local_dbg("[RawSocket:%u] Finishing sending I/O vector %lu of "
                "%lu bytes with status %u.\r\n", (unsigned)sockId,
                (long unsigned)payloadIov, (long unsigned)payloadSize,
                (unsigned)status);

        signal UDPRawSender.finishSending[sockId](
                payloadIov,
                payloadSize,
                status
        );
    }



    // *********************************************************************
    // *                                                                   *
    // *                             Receiving                             *
    // *                                                                   *
    // *********************************************************************

    event error_t IPv6PacketReceiver.startReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        iov_blist_iter_t                    payloadIter;
        size_t                              payloadLen;
        whip6_ipv6_basic_header_t const *   ipv6Hdr;
        whip6_udp_raw_socket_t *            socketPtr;
        error_t                             status;
        udp_socket_id_t                     sockId = NUM_SOCKETS;

        local_dbg("[RawSocket:%u] Received an IPv6 packet, %lu, which "
                "corresponds to incoming packet state %lu.\r\n",
                (unsigned)sockId, (long unsigned)inPacket->packet,
                (long unsigned)inPacket);

        if (inPacket->nextHeaderId != WHIP6_IANA_IPV6_UDP)
        {
            local_dbg("[RawSocket:%u] The next header value, %u, does "
                    "not correspond to UDP, %u. Dropping the received "
                    "packet, %lu.\r\n", (unsigned)sockId,
                    (unsigned)inPacket->nextHeaderId, (unsigned)WHIP6_IANA_IPV6_UDP,
                    (long unsigned)inPacket->packet);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        if ((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_DESTINED_AT_IFACE) == 0)
        {
            local_dbg("[RawSocket:%u] The packet is not meant for the node. "
                    "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                    (long unsigned)inPacket->packet);

            status = ENOROUTE;
            goto FAILURE_ROLLBACK_0;
        }
        ipv6Hdr = &inPacket->packet->header;
        payloadLen = whip6_ipv6BasicHeaderGetPayloadLength(ipv6Hdr);
        if (payloadLen <= inPacket->payloadOffset ||
                payloadLen - inPacket->payloadOffset < sizeof(udp_header_t))
        {
            local_dbg("[RawSocket:%u] The packet size, %lu, is invalid for "
                    "a UDP datagram.Dropping the received packet, %lu.\r\n",
                    (unsigned)sockId, (unsigned long)(payloadLen - inPacket->payloadOffset),
                    (long unsigned)inPacket->packet);

            status = ESIZE;
            goto FAILURE_ROLLBACK_0;
        }
        whip6_iovIteratorClone(&inPacket->payloadIter, &payloadIter);
        if (whip6_iovIteratorReadAndMoveForward(
                    &payloadIter,
                    (uint8_t_xdata *)&m_tmpUdpHeader,
                    sizeof(udp_header_t)) != sizeof(udp_header_t))
        {
            local_dbg("[RawSocket:%u] The packet is inconsistent. "
                    "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                    (long unsigned)inPacket->packet);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        sockId =
                findSocketForPortNo(
                        whip6_udpHeaderGetDstPort(&m_tmpUdpHeader)
                );
        if (sockId >= NUM_SOCKETS)
        {
            local_dbg("[RawSocket:%u] There is no socket open for %u. "
                    "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                    (unsigned)whip6_udpHeaderGetDstPort(&m_tmpUdpHeader),
                    (long unsigned)inPacket->packet);

            // NOTICE iwanicki 2013-12-16:
            // We should normally send a Destination
            // unreachable ICMPv6 message here (assuming
            // that the checksum is all right). For now,
            // however, let's ignore ICMPv6.
            status = EOFF;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr = &(m_sockets[sockId]);
        if (socketPtr->in.ipv6StatePtr != NULL)
        {
            local_dbg("[RawSocket:%u] The socket is busy. "
                    "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                    (long unsigned)inPacket->packet);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        /*if (! isBound(socketPtr))
        {
            // NOTICE iwanicki 2013-12-16:
            // We should normally send a Destination
            // unreachable ICMPv6 message here (assuming
            // that the checksum is all right). For now,
            // however, let's ignore ICMPv6.
            status = EOFF;
            goto FAILURE_ROLLBACK_0;
        }*/
        socketPtr->in.iovTotal = whip6_udpHeaderGetLength(&m_tmpUdpHeader);
        if (socketPtr->in.iovTotal < sizeof(udp_header_t) ||
                socketPtr->in.iovTotal > payloadLen)
        {
            local_dbg("[RawSocket:%u] The packet is too small to be correct. "
                    "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                    (long unsigned)inPacket->packet);

            status = ESIZE;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr->in.iovProcessed = 0;
        socketPtr->in.srcSockAddr.udpPortNo =
                whip6_udpHeaderGetSrcPort(&m_tmpUdpHeader);
        if (isConnected(socketPtr))
        {
            if (socketPtr->in.srcSockAddr.udpPortNo != socketPtr->remoteAddr.udpPortNo ||
                    whip6_shortMemCmp(
                            (uint8_t_xdata const *)whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                            (uint8_t_xdata const *)&socketPtr->remoteAddr.ipv6Addr,
                            sizeof(ipv6_addr_t)
                    ) != 0)
            {
                local_dbg("[RawSocket:%u] The receiver expects packets from somebody else. "
                        "Dropping the received packet, %lu.\r\n", (unsigned)sockId,
                        (long unsigned)inPacket->packet);

                status = EOFF;
                goto FAILURE_ROLLBACK_0;
            }
        }
        whip6_shortMemCpy(
                (uint8_t_xdata const *)whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                (uint8_t_xdata *)&socketPtr->in.srcSockAddr.ipv6Addr,
                sizeof(ipv6_addr_t)
        );
        socketPtr->in.csValue = whip6_udpHeaderGetChecksum(&m_tmpUdpHeader);
        socketPtr->in.ipv6StatePtr = inPacket;
        post handleIncomingPacketTask();

        local_dbg("[RawSocket:%u] Successfuly accepted the received an "
                "IPv6 packet, %lu, which corresponds to incoming packet "
                "state %lu for possible delivery.\r\n",
                (unsigned)sockId, (long unsigned)inPacket->packet,
                (long unsigned)inPacket);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void handleIncomingPacketTask()
    {
        whip6_udp_raw_socket_t *      socketPtr;
        udp_socket_id_t               sockId;
        udp_socket_id_t               nextSockId;

        sockId = m_currInSock;
        do
        {
            nextSockId = sockId + 1;
            if (nextSockId >= NUM_SOCKETS)
            {
                nextSockId = 0;
            }
            socketPtr = &(m_sockets[sockId]);
            if (socketPtr->in.ipv6StatePtr != NULL &&
                    // NOTICE iwanicki 2013-12-17:
                    // This condition checks if we are not delivering
                    // the given packet.
                    socketPtr->in.iovProcessed <= socketPtr->in.iovTotal)
            {
                error_t   status;

                if (socketPtr->in.iovProcessed == 0)
                {
                    local_dbg("[RawSocket:%u] Starting computing the checksum "
                            "for the received packet, %lu.\r\n", (unsigned)sockId,
                            (long unsigned)socketPtr->in.ipv6StatePtr->packet);

                    status =
                            initChecksumComputationForInPacket(
                                    socketPtr
                            );
                }
                else if (socketPtr->in.iovProcessed < socketPtr->in.iovTotal)
                {
                    local_dbg("[RawSocket:%u] Continuing computing the checksum "
                            "for the received packet, %lu.\r\n", (unsigned)sockId,
                            (long unsigned)socketPtr->in.ipv6StatePtr->packet);

                    status =
                            contChecksumComputationForInPacket(
                                    socketPtr,
                                    socketPtr->in.iovTotal - socketPtr->in.iovProcessed
                            );
                }
                else // if (socketPtr->in.iovProcessed == socketPtr->in.iovTotal)
                {
                    local_dbg("[RawSocket:%u] Finishing computing the checksum "
                            "for the received packet, %lu.\r\n", (unsigned)sockId,
                            (long unsigned)socketPtr->in.ipv6StatePtr->packet);

                    status =
                            endChecksumComputationForInPacket(
                                    socketPtr,
                                    sockId
                            );
                }

                if (status != SUCCESS)
                {
                    finishHandlingInPacket(sockId, FAIL);
                }

                m_currInSock = nextSockId;
                post handleIncomingPacketTask();
            }
            sockId = nextSockId;
        }
        while (sockId != m_currInSock);
    }



    static error_t initChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr
    )
    {
        whip6_ipv6_basic_header_t const *   ipv6Hdr;
        size_t                              numAdvanced;

        whip6_ipv6ChecksumComputationInit(
                &socketPtr->in.csComp
        );
        ipv6Hdr = &socketPtr->in.ipv6StatePtr->packet->header;
        whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
                &socketPtr->in.csComp,
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(ipv6Hdr),
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(ipv6Hdr),
                socketPtr->in.iovTotal,
                WHIP6_IANA_IPV6_UDP
        );
        socketPtr->in.iovProcessed = sizeof(udp_header_t);
        whip6_iovIteratorClone(
                &socketPtr->in.ipv6StatePtr->payloadIter,
                &socketPtr->in.iovIter
        );
        numAdvanced =
                whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                        &socketPtr->in.csComp,
                        &socketPtr->in.iovIter,
                        sizeof(udp_header_t)
                );
        return numAdvanced == sizeof(udp_header_t) ? SUCCESS : FAIL;
    }



    static error_t contChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr,
            size_t numRequested
    )
    {
        size_t   numAdvanced;

        if (numRequested > MAX_BYTES_PROCESSED_PER_TASK)
        {
            numRequested = MAX_BYTES_PROCESSED_PER_TASK;
        }

        numAdvanced =
                whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
                        &socketPtr->in.csComp,
                        &socketPtr->in.iovIter,
                        numRequested
                );

        socketPtr->in.iovProcessed += numAdvanced;

        return numAdvanced == numRequested ? SUCCESS : FAIL;
    }



    static error_t endChecksumComputationForInPacket(
            whip6_udp_raw_socket_t * socketPtr,
            udp_socket_id_t sockId
    )
    {
        whip6_iov_blist_t *           payloadIov;
        ipv6_checksum_t               computedCs;

        computedCs =
                whip6_ipv6ChecksumComputationFinalize(
                        &socketPtr->in.csComp
                );
        if (computedCs != 0)
        {
            local_dbg("[RawSocket:%u] The computed checksum, %u, does "
                    "not match the one in the header, %u.\r\n", (unsigned)sockId,
                    (unsigned)computedCs, (unsigned)socketPtr->in.csValue);

            goto FAILURE_ROLLBACK_0;
        }
        whip6_iovIteratorClone(
                &socketPtr->in.ipv6StatePtr->payloadIter,
                &socketPtr->in.iovIter
        );
        if (whip6_udpStripeDataFromIncomingIpv6PacketCarryingUdpDatagram(
                        &socketPtr->in.iovIter,
                        &socketPtr->in.iovHead,
                        &payloadIov))
        {
            local_dbg("[RawSocket:%u] Failed to extract the payload from "
                    "the packet.\r\n", (unsigned)sockId);

            goto FAILURE_ROLLBACK_0;
        }

        local_dbg("[RawSocket:%u] Pass the payload, %lu, of %lu bytes "
                "to a higher layer.\r\n", (unsigned)sockId,
                (long unsigned)payloadIov, (long unsigned)socketPtr->in.iovTotal);

        // NOTICE iwanicki 2013-12-16:
        // This length decrement protects us from
        // finishing the computation more than once.
        socketPtr->in.iovTotal -= sizeof(udp_header_t);
        if (signal UDPRawReceiver.startReceiving[sockId](
                        payloadIov,
                        socketPtr->in.iovTotal,
                        &socketPtr->in.srcSockAddr) != SUCCESS)
        {
            local_dbg("[RawSocket:%u] Failed to pass the payload from "
                    "to a higher layer.\r\n", (unsigned)sockId);

            goto FAILURE_ROLLBACK_1;
        }
        return SUCCESS;

    FAILURE_ROLLBACK_1:
        if (whip6_udpRestoreDataToIncomingIpv6PacketCarryingUdpDatagram(
                        &socketPtr->in.iovIter,
                        payloadIov,
                        &socketPtr->in.iovHead))
        {
            LOCAL_FATAL_FAILURE;
        }
        socketPtr->in.iovTotal += sizeof(udp_header_t);
    FAILURE_ROLLBACK_0:
        return FAIL;
    }



    command void UDPRawReceiver.finishReceiving[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov
    )
    {
        whip6_udp_raw_socket_t *      socketPtr;

        // ASSUMPTION: sockId < NUM_SOCKETS
        socketPtr = &(m_sockets[sockId]);
        if (socketPtr->in.ipv6StatePtr == NULL)
        {
            LOCAL_FATAL_FAILURE;
            return;
        }
        if (whip6_udpRestoreDataToIncomingIpv6PacketCarryingUdpDatagram(
                        &socketPtr->in.iovIter,
                        payloadIov,
                        &socketPtr->in.iovHead))
        {
            LOCAL_FATAL_FAILURE;
        }
        socketPtr->in.iovTotal += sizeof(udp_header_t);
        finishHandlingInPacket(sockId, SUCCESS);
    }



    static void finishHandlingInPacket(
            udp_socket_id_t sockId, error_t status
    )
    {
        whip6_udp_raw_socket_t *                    socketPtr;
        whip6_ipv6_in_packet_processing_state_t *   ipv6State;

        socketPtr = &(m_sockets[sockId]);

        local_dbg("[RawSocket:%u] Finishing processing the received packet, "
                "%lu, which corresponds to incoming packet state %lu with "
                "status %u.\r\n", (unsigned)sockId,
                (long unsigned)socketPtr->in.ipv6StatePtr->packet,
                (long unsigned)socketPtr->in.ipv6StatePtr, (long)status);

        ipv6State = socketPtr->in.ipv6StatePtr;
        socketPtr->in.ipv6StatePtr = NULL;
        whip6_iovIteratorInvalidate(&ipv6State->payloadIter);
        ipv6State->nextHeaderId = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
        call IPv6PacketReceiver.finishReceivingIPv6Packet(ipv6State, status);
    }



    default event inline error_t UDPRawReceiver.startReceiving[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * srcSockAddr
    )
    {
        LOCAL_FATAL_FAILURE;
        return ENOSYS;
    }



    default event void UDPRawSender.finishSending[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            error_t status
    )
    {
        LOCAL_FATAL_FAILURE;
    }


#undef LOCAL_FATAL_FAILURE
#undef local_dbg
}

