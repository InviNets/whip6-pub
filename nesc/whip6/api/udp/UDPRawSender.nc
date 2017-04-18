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
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A raw sender for UDP datagrams.
 *
 * @author Konrad Iwanicki
 */
interface UDPRawSender
{

    /**
     * Starts sending a datagram with a given payload
     * to a given socket address (or to the remote address
     * the socket is connected to).
     * @param payloadIov An I/O vector containing the
     *   datagram payload.
     * @param payloadSize The length of the datagram payload.
     * @param dstSockAddrOrNull The destination socket address.
     *   If NULL, then the socket must be connected to some
     *   remote address and that remote address will be used.
     * @return SUCCESS if the sending has been
     *   started successfully, in which case the
     *   <tt>finishSending</tt> event is guaranteed to be
     *   signaled, or an error code otherwise, in which case no
     *   <tt>finishSending</tt> event will be signaled.
     *   Possible errors:
     *   - ESTATE if the socket is not bound or <tt>dstSockAddrOrNull</tt>
     *     is NULL and the socket is not connected.
     *   - EBUSY if the socket is already sending a datagram.
     *   - ENOMEM if there was no memory to send the datagram.
     *   - ESIZE if the payload size is too large.
     *   - EINVAL if payload arguments are invalid.
     *   - FAIL if a fatal error occurred.
     */
    command error_t startSending(
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * dstSockAddrOrNull
    );

    /**
     * Signaled when sending a datagram has finished. The
     * event does not imply that the datagram has been sent,
     * but only that no sending takes place anymore.
     * @param payloadIov The original I/O vector containing
     *   the datagram payload.
     * @param payloadSize The length of the datagram payload.
     * @param status The status of the sending.
     */
    event void finishSending(
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            error_t status
    );

}
