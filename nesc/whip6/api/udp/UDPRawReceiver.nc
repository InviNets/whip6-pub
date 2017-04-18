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
 * A raw receiver for UDP datagrams.
 *
 * @author Konrad Iwanicki
 */
interface UDPRawReceiver
{
    /**
     * Starts receiving a datagram with a given payload
     * from a given socket address.
     * @param payloadIov An I/O vector containing the
     *   datagram payload.
     * @param payloadSize The length of the datagram payload.
     * @param srcSockAddr The source socket address.
     * @return SUCCESS if the implementer of the handler
     *   is ready to receive the payload, in which case
     *   the <tt>finishReceiving</tt> command is expected
     *   to be invoked with the payloadIov not modified,
     *   or an error code otherwise, in which case no
     *   <tt>finishReceiving</tt> command is expected to
     *   be invoked.
     */
    event error_t startReceiving(
            whip6_iov_blist_t * payloadIov,
            size_t payloadSize,
            whip6_udp_socket_addr_t const * srcSockAddr
    );

    /**
     * Signaled when receiving a UDP datagram with a given
     * payload has finished and the datagram (including the
     * payload) may be freed.
     * @param payloadIov The original I/O vector containing
     *   the payload.
     */
    command void finishReceiving(
            whip6_iov_blist_t * payloadIov
    );

}
