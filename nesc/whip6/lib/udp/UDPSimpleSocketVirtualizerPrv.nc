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
#include <base/ucIoVecAllocation.h>
#include <base/ucString.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6PacketTypes.h>
#include <udp/ucUdpHeaderManipulation.h>
#include <udp/ucUdpBasicTypes.h>

// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

/**
 * A virtualizer for simple UDP sockets.
 *
 * @param num_sockets The number of sockets.
 * @param max_bytes_copied_in_task The maximal
 *   number of bytes copied in a single task.
 *
 * @author Konrad Iwanicki
 */
generic module UDPSimpleSocketVirtualizerPrv(
        udp_socket_id_t num_sockets,
        size_t max_bytes_copied_in_task
)
{
    provides
    {
        interface Init;
        interface UDPSimpleReceiver[udp_socket_id_t sockId];
        interface UDPSimpleSender[udp_socket_id_t sockId];
    }
    uses
    {
        interface UDPRawReceiver[udp_socket_id_t sockId];
        interface UDPRawSender[udp_socket_id_t sockId];
        interface UDPSocketController[udp_socket_id_t sockId];
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
        MAX_UDP_PAYLOAD = WHIP6_IPV6_MIN_MTU - sizeof(udp_header_t),
    };

    enum
    {
        MAX_BYTES_COPIED_IN_TASK = max_bytes_copied_in_task,
    };

    enum
    {
        SOCKET_IN_STATE_FLAG_BUF_PROVIDED = (1 << 7),
        SOCKET_IN_STATE_FLAG_IOV_PROVIDED = (1 << 6),
        SOCKET_IN_STATE_FLAG_DEL_PENDING = (1 << 5),
        
        SOCKET_OUT_STATE_FLAG_TRM_IN_PROGRESS = (1 << 1),
        SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED = (1 << 0),
    };


    typedef struct socket_in_state_s
    {
        uint8_t_xdata *                   bufPtr;
        size_t                            bufLen;
        whip6_udp_socket_addr_t *         sockAddrPtr;
        whip6_iov_blist_t *               payloadPtr;
        size_t                            payloadLen;
        size_t                            bufOff;
        iov_blist_iter_t                  payloadIter;
    } socket_in_state_t;



    typedef struct socket_out_state_s
    {
        uint8_t_xdata const *             bufPtr;
        size_t                            bufLen;
        whip6_udp_socket_addr_t const *   sockAddrPtr;
        whip6_iov_blist_t *               payloadPtr;
        size_t                            bufOff;
        iov_blist_iter_t                  payloadIter;
    } socket_out_state_t;



    typedef struct udp_simple_socket_s
    {
        uint8_t              flags;
        socket_out_state_t   out;
        socket_in_state_t    in;
    } udp_simple_socket_t;

    typedef udp_simple_socket_t udp_simple_socket_t_xdata; typedef udp_simple_socket_t_xdata whip6_udp_simple_socket_t;



    whip6_udp_simple_socket_t   m_sockets[NUM_SOCKETS];
    udp_socket_id_t             m_currInSock = 0;
    udp_socket_id_t             m_currOutSock = 0;



    error_t startSendingDatagram(
            uint8_t_xdata const * bufPtr,
            whip6_udp_socket_addr_t const * sockAddrOrNull,
            size_t bufLen,
            udp_socket_id_t sockId
    );
    void finishSendingDatagram(
            udp_socket_id_t sockId,
            error_t status
    );
    error_t startReceivingDatagram(
            uint8_t_xdata * bufPtr,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            size_t bufLen,
            udp_socket_id_t sockId
    );
    error_t startHandlingIncomingIov(
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * srcSockAddr,
            udp_socket_id_t sockId
    );
    void finishHandlingIncomingIov(
            udp_socket_id_t sockId
    );
    void finishReceivingDatagram(
            udp_socket_id_t sockId,
            error_t status
    );

    task void processOutgoingPacketsTask();
    task void processIncomingPacketsTask();


    command error_t Init.init()
    {
        udp_socket_id_t   sockId;
        for (sockId = 0; sockId < NUM_SOCKETS; ++sockId)
        {
            m_sockets[sockId].flags = 0;
        }
        return SUCCESS;
    }



    // *********************************************************************
    // *                                                                   *
    // *                              Sending                              *
    // *                                                                   *
    // *********************************************************************

    command inline error_t UDPSimpleSender.startSending[udp_socket_id_t sockId](
            uint8_t_xdata const * bufPtr,
            size_t bufLen
    )
    {
        return startSendingDatagram(bufPtr, NULL, bufLen, sockId);
    }



    command inline error_t UDPSimpleSender.startSendingTo[udp_socket_id_t sockId](
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr
    )
    {
        return sockAddr == NULL ?
                EINVAL : startSendingDatagram(bufPtr, sockAddr, bufLen, sockId);
    }



    error_t startSendingDatagram(
            uint8_t_xdata const * bufPtr,
            whip6_udp_socket_addr_t const * sockAddrOrNull,
            size_t bufLen,
            udp_socket_id_t sockId
    )
    {
        whip6_udp_simple_socket_t *   socketPtr;
        error_t                       status;

        local_dbg("[SimpleSocket:%u] Attempting to start sending buffer %lu "
                "of %lu bytes.\r\n", (unsigned)sockId, (long unsigned)bufPtr,
                (long unsigned)bufLen);

        // ASSUMPTION: sockId < NUM_SOCKETS
        if (bufLen > MAX_UDP_PAYLOAD)
        {
            local_dbg("[SimpleSocket:%u] Sending buffer %lu failed, because "
                    "the payload is too large!\r\n", (unsigned)sockId,
                    (long unsigned)bufPtr);

            status = ESIZE;
            goto FAILURE_ROLLBACK_0;
        }
        if (bufLen > 0 && bufPtr == NULL)
        {
            local_dbg("[SimpleSocket:%u] Sending buffer %lu failed, because "
                    "the payload is NULL!\r\n", (unsigned)sockId,
                    (long unsigned)bufPtr);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr = &(m_sockets[sockId]);
        if ((socketPtr->flags & SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED) != 0)
        {
            local_dbg("[SimpleSocket:%u] Sending buffer %lu failed, because "
                    "the socket is busy!\r\n", (unsigned)sockId,
                    (long unsigned)bufPtr);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        if (bufLen == 0)
        {
            socketPtr->out.payloadPtr = NULL;
        }
        else
        {
            socketPtr->out.payloadPtr = whip6_iovAllocateChain(bufLen, NULL);
            if (socketPtr->out.payloadPtr == NULL)
            {
                local_dbg("[SimpleSocket:%u] Sending buffer %lu failed, because "
                        "there is no memory for an I/O vector!\r\n",
                        (unsigned)sockId, (long unsigned)bufPtr);

                status = ENOMEM;
                goto FAILURE_ROLLBACK_0;
            }
        }
        socketPtr->flags |= SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED;
        socketPtr->out.bufPtr = bufPtr;
        socketPtr->out.bufLen = bufLen;
        socketPtr->out.sockAddrPtr = sockAddrOrNull;
        socketPtr->out.bufOff = 0;
        whip6_iovIteratorInitToBeginning(
                socketPtr->out.payloadPtr,
                &socketPtr->out.payloadIter
        );
        post processOutgoingPacketsTask();

        local_dbg("[SimpleSocket:%u] Successfully started sending buffer %lu "
                "of %lu bytes.\r\n", (unsigned)sockId, (long unsigned)bufPtr,
                (long unsigned)bufLen);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void processOutgoingPacketsTask()
    {
        whip6_udp_simple_socket_t *   socketPtr;
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
            if ((socketPtr->flags & (SOCKET_OUT_STATE_FLAG_TRM_IN_PROGRESS | SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED)) ==
                    SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED)
            {
                size_t   leftBytes;
                size_t   writtenBytes;

                leftBytes = socketPtr->out.bufLen - socketPtr->out.bufOff;

                if (leftBytes == 0)
                {
                    if (call UDPRawSender.startSending[sockId](
                                socketPtr->out.payloadPtr,
                                socketPtr->out.bufLen,
                                socketPtr->out.sockAddrPtr) != SUCCESS)
                    {
                        local_dbg("[SimpleSocket:%u] Failed to pass "
                            "I/O vector %lu to the raw socket layer for "
                            "sending.\r\n", (unsigned)sockId,
                            (long unsigned)socketPtr->out.payloadPtr);

                        finishSendingDatagram(sockId, FAIL);
                    }
                    else
                    {
                        local_dbg("[SimpleSocket:%u] Successfully passed "
                            "I/O vector %lu to the raw socket layer for "
                            "sending.\r\n", (unsigned)sockId,
                            (long unsigned)socketPtr->out.payloadPtr);

                        socketPtr->flags |= SOCKET_OUT_STATE_FLAG_TRM_IN_PROGRESS;
                    }
                }
                else
                {
                    if (leftBytes > MAX_BYTES_COPIED_IN_TASK)
                    {
                        leftBytes = MAX_BYTES_COPIED_IN_TASK;
                    }

                    writtenBytes =
                            whip6_iovIteratorWriteAndMoveForward(
                                    &socketPtr->out.payloadIter,
                                    socketPtr->out.bufPtr + socketPtr->out.bufOff,
                                    leftBytes
                            );

                    if (writtenBytes != leftBytes)
                    {
                        local_dbg("[SimpleSocket:%u] Failed to copy %lu "
                            "bytes from buffer %lu into I/O vector %lu. "
                            "Only %lu bytes were copied.\r\n",
                            (unsigned)sockId, (long unsigned)leftBytes,
                            (long unsigned)socketPtr->out.bufPtr,
                            (long unsigned)socketPtr->out.payloadPtr,
                            (long unsigned)writtenBytes);

                        finishSendingDatagram(sockId, FAIL);
                    }
                    else
                    {
                        local_dbg("[SimpleSocket:%u] Successfully copied %lu "
                            "bytes from buffer %lu into I/O vector %lu.\r\n",
                            (unsigned)sockId, (long unsigned)writtenBytes,
                            (long unsigned)socketPtr->out.bufPtr,
                            (long unsigned)socketPtr->out.payloadPtr);

                        socketPtr->out.bufOff += writtenBytes;
                    }
                }
                m_currOutSock = nextSockId;
                post processOutgoingPacketsTask();
            }
            sockId = nextSockId;
        }
        while (sockId != m_currOutSock);
    }



    event inline void UDPRawSender.finishSending[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            error_t status
    )
    {
        // ASSUMPTION: sockId < NUM_SOCKETS
        // ASSUMPTION: m_sockets[sockId].payloadPtr == payloadIov
        // ASSUMPTION: m_sockets[sockId].bufLen == payloadSize
        local_dbg("[SimpleSocket:%u] The raw socket layer finished "
            "sending I/O vector %lu with status %u.\r\n",
            (unsigned)sockId, (long unsigned)payloadIov, (unsigned)status);

        finishSendingDatagram(sockId, status != SUCCESS ? FAIL : SUCCESS);
    }



    void finishSendingDatagram(
            udp_socket_id_t sockId,
            error_t status
    )
    {
        whip6_udp_simple_socket_t *   socketPtr;

        socketPtr = &(m_sockets[sockId]);
        socketPtr->flags &= ~(uint8_t)(
                SOCKET_OUT_STATE_FLAG_TRM_IN_PROGRESS |
                SOCKET_OUT_STATE_FLAG_BUF_AND_IOV_PROVIDED);
        if (socketPtr->out.payloadPtr != NULL)
        {
            whip6_iovFreeChain(socketPtr->out.payloadPtr);
            socketPtr->out.payloadPtr = NULL;
        }

        local_dbg("[SimpleSocket:%u] Finished sending buffer %lu "
            "of %lu bytes with status %u.\r\n", (unsigned)sockId,
            (long unsigned)socketPtr->out.bufPtr,
            (long unsigned)socketPtr->out.bufLen, (unsigned)status);

        signal UDPSimpleSender.finishSending[sockId](
                socketPtr->out.bufPtr,
                socketPtr->out.bufLen,
                socketPtr->out.sockAddrPtr,
                status
        );
    }



    // *********************************************************************
    // *                                                                   *
    // *                             Receiving                             *
    // *                                                                   *
    // *********************************************************************

    command inline error_t UDPSimpleReceiver.startReceiving[udp_socket_id_t sockId](
            uint8_t_xdata * bufPtr,
            size_t bufLen
    )
    {
        return startReceivingDatagram(bufPtr, NULL, bufLen, sockId);
    }



    command inline error_t UDPSimpleReceiver.startReceivingFrom[udp_socket_id_t sockId](
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddr
    )
    {
        return sockAddr == NULL ?
                EINVAL : startReceivingDatagram(bufPtr, sockAddr, bufLen, sockId);
    }



    error_t startReceivingDatagram(
            uint8_t_xdata * bufPtr,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            size_t bufLen,
            udp_socket_id_t sockId
    )
    {
        whip6_udp_simple_socket_t *   socketPtr;
        error_t                       status;

        local_dbg("[SimpleSocket:%u] Attempting to start receiving into buffer %lu "
                "of %lu bytes.\r\n", (unsigned)sockId, (long unsigned)bufPtr,
                (long unsigned)bufLen);

        // ASSUMPTION: sockId < NUM_SOCKETS
        if (bufPtr == NULL && bufLen > 0)
        {
            local_dbg("[SimpleSocket:%u] Receiving into buffer %lu failed, "
                    "because the buffer is NULL.\r\n", (unsigned)sockId,
                    (long unsigned)bufPtr);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr = &(m_sockets[sockId]);
        if ((socketPtr->flags & SOCKET_IN_STATE_FLAG_BUF_PROVIDED) != 0)
        {
            local_dbg("[SimpleSocket:%u] Receiving into buffer %lu failed, "
                    "because the socket is busy.\r\n", (unsigned)sockId,
                    (long unsigned)bufPtr);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr->flags |= SOCKET_IN_STATE_FLAG_BUF_PROVIDED;
        socketPtr->in.bufPtr = bufPtr;
        socketPtr->in.bufLen = bufLen;
        socketPtr->in.sockAddrPtr = sockAddrOrNull;

        local_dbg("[SimpleSocket:%u] Successfully started receiving into "
                "buffer %lu of %lu bytes.\r\n", (unsigned)sockId,
                (long unsigned)bufPtr, (long unsigned)bufLen);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    event inline error_t UDPRawReceiver.startReceiving[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * srcSockAddr
    )
    {
        return startHandlingIncomingIov(
                payloadIov,
                payloadSize,
                srcSockAddr,
                sockId
        );
    }



    error_t startHandlingIncomingIov(
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * srcSockAddr,
            udp_socket_id_t sockId
    )
    {
        whip6_udp_simple_socket_t *   socketPtr;
        error_t                       status;

        local_dbg("[SimpleSocket:%u] Received I/O vector %lu of %lu bytes.\r\n",
                (unsigned)sockId, (long unsigned)payloadIov,
                (long unsigned)payloadSize);

        // ASSUMPTION: sockId < NUM_SOCKETS
        socketPtr = &(m_sockets[sockId]);
        if (payloadIov == NULL && payloadSize > 0)
        {
            local_dbg("[SimpleSocket:%u] The received I/O vector, %lu, "
                    "is NULL. Ignoring it.\r\n",
                    (unsigned)sockId, (long unsigned)payloadIov);

            status = EINVAL;
            goto FAILURE_ROLLBACK_0;
        }
        // NOTICE iwanicki 2013-12-17:
        // Well, we could buffer the packet in the hope that
        // somebody will receive it, but actually nobody
        // can be even expecting anything from the socket.
        if ((socketPtr->flags & SOCKET_IN_STATE_FLAG_BUF_PROVIDED) == 0)
        {
            local_dbg("[SimpleSocket:%u] The received I/O vector, %lu, "
                    "is not expected. Ignoring it.\r\n",
                    (unsigned)sockId, (long unsigned)payloadIov);

            status = EOFF;
            goto FAILURE_ROLLBACK_0;
        }
        // NOTICE iwanicki 2013-12-17:
        // Here, in turn, we could have a queue for
        // packets. Let's leave it out for now.
        if ((socketPtr->flags & (SOCKET_IN_STATE_FLAG_IOV_PROVIDED | SOCKET_IN_STATE_FLAG_DEL_PENDING)) != 0)
        {
            local_dbg("[SimpleSocket:%u] The received I/O vector, %lu, "
                    "cannot be received because another I/O vector, %lu, "
                    "is being received. Ignoring it.\r\n",
                    (unsigned)sockId, (long unsigned)payloadIov,
                    (long unsigned)socketPtr->in.payloadPtr);

            status = EBUSY;
            goto FAILURE_ROLLBACK_0;
        }
        socketPtr->flags |= SOCKET_IN_STATE_FLAG_IOV_PROVIDED;
        socketPtr->in.payloadPtr = payloadIov;
        socketPtr->in.payloadLen = payloadSize;
        socketPtr->in.bufOff = 0;
        whip6_iovIteratorInitToBeginning(payloadIov, &socketPtr->in.payloadIter);
        if (socketPtr->in.sockAddrPtr != NULL)
        {
            whip6_shortMemCpy(
                    (uint8_t_xdata const *)srcSockAddr,
                    (uint8_t_xdata *)socketPtr->in.sockAddrPtr,
                    sizeof(whip6_udp_socket_addr_t)
            );
        }
        post processIncomingPacketsTask();

        local_dbg("[SimpleSocket:%u] The received I/O vector, %lu, of %lu "
                "bytes has been accepted for potential delivery.\r\n",
                (unsigned)sockId, (long unsigned)payloadIov,
                (long unsigned)payloadSize);

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return status;
    }



    task void processIncomingPacketsTask()
    {
        whip6_udp_simple_socket_t *   socketPtr;
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
            if ((socketPtr->flags & (SOCKET_IN_STATE_FLAG_IOV_PROVIDED | SOCKET_IN_STATE_FLAG_DEL_PENDING)) != 0)
            {
                if ((socketPtr->flags & SOCKET_IN_STATE_FLAG_DEL_PENDING) != 0)
                {
                    finishReceivingDatagram(
                            sockId,
                            socketPtr->in.payloadLen <= socketPtr->in.bufLen ?
                                    SUCCESS : ESIZE
                    );
                }
                else
                {
                    size_t   leftBytes;
                    size_t   readBytes;

                    leftBytes =
                            socketPtr->in.payloadLen < socketPtr->in.bufLen ?
                                    socketPtr->in.payloadLen : socketPtr->in.bufLen;
                    leftBytes -= socketPtr->in.bufOff;

                    if (leftBytes == 0)
                    {
                        local_dbg("[SimpleSocket:%u] All bytes from I/O vector "
                                "%lu have been copied into buffer %lu.\r\n",
                                (unsigned)sockId,
                                (long unsigned)socketPtr->in.payloadPtr,
                                (long unsigned)socketPtr->in.bufPtr);

                        socketPtr->flags |= SOCKET_IN_STATE_FLAG_DEL_PENDING;
                        finishHandlingIncomingIov(sockId);
                    }
                    else
                    {
                        if (leftBytes > MAX_BYTES_COPIED_IN_TASK)
                        {
                            leftBytes = MAX_BYTES_COPIED_IN_TASK;
                        }

                        readBytes =
                                whip6_iovIteratorReadAndMoveForward(
                                        &socketPtr->in.payloadIter,
                                        socketPtr->in.bufPtr + socketPtr->in.bufOff,
                                        leftBytes
                                );

                        if (readBytes != leftBytes)
                        {
                            local_dbg("[SimpleSocket:%u] Failed to copy "
                                    " %lu bytes from I/O vector %lu into "
                                    "buffer %lu. Copied %lu bytes instead.\r\n",
                                    (unsigned)sockId, (long unsigned)leftBytes,
                                    (long unsigned)socketPtr->in.payloadPtr,
                                    (long unsigned)socketPtr->in.bufPtr,
                                    (long unsigned)readBytes);

                            finishHandlingIncomingIov(sockId);
                        }
                        else
                        {
                            local_dbg("[SimpleSocket:%u] Successfully copied "
                                    " %lu bytes from I/O vector %lu into "
                                    "buffer %lu.\r\n", (unsigned)sockId,
                                    (long unsigned)readBytes,
                                    (long unsigned)socketPtr->in.payloadPtr,
                                    (long unsigned)socketPtr->in.bufPtr);

                            socketPtr->in.bufOff += readBytes;
                        }
                    }
                }

                m_currInSock = nextSockId;
                post processIncomingPacketsTask();
            }
            sockId = nextSockId;
        }
        while (sockId != m_currInSock);
    }



    void finishHandlingIncomingIov(udp_socket_id_t sockId)
    {
        whip6_udp_simple_socket_t *   socketPtr;

        socketPtr = &(m_sockets[sockId]);
        socketPtr->flags &= ~(uint8_t)SOCKET_IN_STATE_FLAG_IOV_PROVIDED;

        local_dbg("[SimpleSocket:%u] Finishing processing I/O vector, %lu.\r\n",
                (unsigned)sockId, (long unsigned)socketPtr->in.payloadPtr);

        call UDPRawReceiver.finishReceiving[sockId](
                socketPtr->in.payloadPtr
        );
    }



    void finishReceivingDatagram(
            udp_socket_id_t sockId,
            error_t status
    )
    {
        whip6_udp_simple_socket_t *   socketPtr;

        socketPtr = &(m_sockets[sockId]);
        socketPtr->flags &= ~(uint8_t)(
                SOCKET_IN_STATE_FLAG_BUF_PROVIDED |
                SOCKET_IN_STATE_FLAG_DEL_PENDING);

        local_dbg("[SimpleSocket:%u] Received a (possibly truncated) "
                "datagram payload of %lu bytes into buffer %lu "
                "with status %u.\r\n", (unsigned)sockId,
                (long unsigned)socketPtr->in.bufPtr,
                (long unsigned)socketPtr->in.payloadLen,
                (unsigned)status);

        signal UDPSimpleReceiver.finishReceiving[sockId](
                socketPtr->in.bufPtr,
                socketPtr->in.payloadLen,
                socketPtr->in.sockAddrPtr,
                status
        );
    }



    // *********************************************************************
    // *                                                                   *
    // *                             Defaults                              *
    // *                                                                   *
    // *********************************************************************

    default command inline error_t UDPRawSender.startSending[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * dstSockAddrOrNull
    )
    {
        // NOTICE iwanicki 2013-12-14:
        // This function should never be invoked.
        return FAIL;
    }



    default command inline void UDPRawReceiver.finishReceiving[udp_socket_id_t sockId](
            whip6_iov_blist_t * payloadIov
    )
    {
        // NOTICE iwanicki 2013-12-14:
        // This function should never be invoked.
    }



    default event inline void UDPSimpleSender.finishSending[udp_socket_id_t sockId](
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr,
            error_t status
    )
    {
        // NOTICE iwanicki 2013-12-14:
        // This function should never be invoked.
    }



    default event inline void UDPSimpleReceiver.finishReceiving[udp_socket_id_t sockId](
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            error_t status
    )
    {
        // NOTICE iwanicki 2013-12-14:
        // This function should never be invoked.
    }

#undef local_dbg
}

