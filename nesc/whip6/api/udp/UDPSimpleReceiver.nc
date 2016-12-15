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

#include <ipv6/ucIpv6AddressManipulation.h>
#include <udp/ucUdpBasicTypes.h>



/**
 * A simple receiver for a User Datagram
 * Protocol (UDP) socket.
 *
 * @author Konrad Iwanicki
 */
interface UDPSimpleReceiver
{
    /**
     * Starts receiving data through the socket
     * into a given memory buffer. If the socket is
     * connected, only datagrams from the remote address
     * will be received.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The length of the buffer.
     * @return SUCCESS if the receiving was initiated
     *   successfully, in which case the <tt>finishReceiving</tt>
     *   event is guaranteed to be signaled
     *   eventually, or an error code otherwise, in
     *   which case no <tt>finishReceiving</tt> event
     *   will be signaled. Possible error codes:
     *   - EINVAL if the data buffer pointer is NULL but the
     *     length of the buffer is more than zero.
     *   - EBUSY if the socket is already receiving another
     *      datagram.
     *   - ENOMEM if there is no memory to receive the datagram.
     *   - ESTATE if the socket is not connected or not bound.
     *   - FAIL if an error occurred at a lower layer.
     */
    command error_t startReceiving(
            uint8_t_xdata * bufPtr,
            size_t bufLen
    );

    /**
     * Starts receiving data through the socket
     * into a given memory buffer and upon success
     * returns the address of the sender. If the socket is
     * connected, only datagrams from the remote address
     * will be received.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The length of the buffer.
     * @param sockAddr A buffer for the address of the
     *   datagram sender.
     * @return SUCCESS if the receiving was initiated
     *   successfully, in which case the <tt>finishReceiving</tt>
     *   event is guaranteed to be signaled
     *   eventually, or an error code otherwise, in
     *   which case no <tt>finishReceiving</tt> event
     *   will be signaled. Possible error codes:
     *   - EINVAL if the address buffer is NULL but the
     *     length of the buffer is more than zero or the data
     *     buffer pointer is NULL.
     *   - EBUSY if the socket is already receiving another
     *      datagram.
     *   - ENOMEM if there is no memory to receive the datagram.
     *   - ESTATE if the socket is not bound.
     *   - FAIL if an error occurred at a lower layer.
     */
    command error_t startReceivingFrom(
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddr
    );

    /**
     * Signaled when receiving data in a buffer through
     * the socket has finished. The event does not imply
     * that the data has been received, but only that the
     * buffer is no longer necessary for the networking
     * stack and can be reused.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The received number of bytes in the buffer
     *   (at most the number provided when initiating the
     *   reception, but can also be smaller, even zero).
     * @param sockAddrOrNull The address at which the data
     *   was sourced or NULL if upon sending no address
     *   was provided.
     * @param status The status of the reception. SUCCESS
     *   denotes that the data was correctly received.
     *   Possible error codes:
     *   - ESIZE meaning that the provided buffer was
     *     too small to receive the datagram, but the
     *     buffer is filled with the prefix of the payload.
     *     In this case, <tt>bufLen</tt> will be equal to
     *     the actual size of the payload.
     *   - FAIL if a fatal error on this reception occurred.
     */
    event void finishReceiving(
            uint8_t_xdata * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t * sockAddrOrNull,
            error_t status
    );

}

