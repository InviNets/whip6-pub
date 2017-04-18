/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6AddressManipulation.h>
#include <udp/ucUdpBasicTypes.h>



/**
 * A simple sender for a User Datagram
 * Protocol (UDP) socket.
 *
 * @author Konrad Iwanicki
 */
interface UDPSimpleSender
{
    /**
     * Starts sending data contained in a given
     * memory buffer through the socket. The
     * data must fit in a single UDP datagram.
     * The socket is assumed to have been connected.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The length of the buffer.
     * @return SUCCESS if the sending was initiated
     *   successfully, in which case the <tt>finishSending</tt>
     *   event is guaranteed to be signaled
     *   eventually, or an error code otherwise, in
     *   which case no <tt>finishSending</tt> event
     *   will be signaled. Possible error codes:
     *   - ESIZE if the buffer is too long.
     *   - EINVAL if the buffer pointer is NULL but the length
     *     is positive.
     *   - EBUSY if the socket is already sending another
     *      datagram.
     *   - ENOMEM if there is no memory to send the datagram.
     *   - ESTATE if the socket is not connected or not bound.
     *   - FAIL if passing the resulting datagram to
     *     lower layers has failed.
     */
    command error_t startSending(
            uint8_t_xdata const * bufPtr,
            size_t bufLen
    );

    /**
     * Starts sending data contained in a given
     * memory buffer through the socket to a given
     * UDP destination address. The data must fit in
     * a single UDP datagram. If the socket is
     * connected, the given addres overrides the address
     * to which the socket is connected.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The length of the buffer.
     * @param sockAddr The address of the destination socket.
     * @return SUCCESS if the sending was initiated
     *   successfully, in which case the <tt>finishSending</tt>
     *   event is guaranteed to be signaled
     *   eventually, or an error code otherwise, in
     *   which case no <tt>finishSending</tt> event
     *   will be signaled. Possible error codes:
     *   - ESIZE if the buffer is too long.
     *   - EINVAL if the destination address is invalid or
     *     the buffer pointer is NULL while the length is
     *     positive.
     *   - EBUSY if the socket is already sending another
     *      datagram.
     *   - ENOMEM if there is no memory to send the datagram.
     *   - ESTATE if the socket is not bound.
     *   - FAIL if passing the resulting datagram to
     *     lower layers has failed.
     */
    command error_t startSendingTo(
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr
    );

    /**
     * Signaled when sending data in a buffer through
     * the socket has finished. The event does not imply
     * that the data has been sent, but only that the
     * buffer is no longer necessary for the networking
     * stack and can be reused.
     * @param bufPtr A pointer to the data buffer.
     * @param bufLen The length of the buffer.
     * @param sockAddr The address to which the data
     *   was destined.
     * @param status The status of the sending.
     */
    event void finishSending(
            uint8_t_xdata const * bufPtr,
            size_t bufLen,
            whip6_udp_socket_addr_t const * sockAddr,
            error_t status
    );

}
