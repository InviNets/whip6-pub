/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A forwarder of IPv6 packets over
 * a 6LoWPAN-compatible network interface.
 *
 * @author Konrad Iwanicki
 */
interface LoWPANIPv6PacketForwarder
{
    /**
     * Starts forwarding an IPv6 packet to a given
     * 802.15.4 address.
     * @param packet A pointer to the packet to be
     *   forwarded. The implementer takes over the
     *   ownership of the packet.
     * @param llAddr The link-layer 802.15.4 address
     *   to which the packet should be forwarded.
     * @return SUCCESS if forwarding the packet has been
     *   started successfully, in which case the
     *   <tt>forwardingIpv6PacketFinished</tt> event
     *   is guaranteed to be signaled for the packet;
     *   or an error code otherwise, in which case
     *   no <tt>forwardingIpv6PacketFinished</tt> event
     *   will be signaled for the packet.
     */
    command error_t startForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr
    );

    /**
     * Stops forwarding an IPv6 packet.
     * @param packet The packet forwarding which should
     *   be stopped.
     * @return SUCCESS if forwarding the packet has been
     *   stopped successfully, in which case the
     *   <tt>forwardingIpv6PacketFinished</tt> event is
     *   still guaranteed to be signaled for the packet;
     *   EINVAL if the given packet is not being forwarded,
     *   in which case no <tt>forwardingIpv6PacketFinished</tt>
     *   event will be signaled for the packet; or another
     *   error code, in which case the
     *   <tt>forwardingIpv6PacketFinished</tt> is still
     *   guaranteed to be signaled.
     */
    command error_t stopForwardingIpv6Packet(
            whip6_ipv6_packet_t * packet
    );

    /**
     * Signaled when forwarding of a given IPv6 packet
     * has finished. Note that it does not mean that the
     * packet has been successfully forwarded.
     * @param packet A pointer to the packet forwarding which
     *   has finished. The implementer of the handler takes
     *   over the ownership of the packet.
     * @param llAddr The link-layer 802.15.4 address to
     *   which the packet was to be forwarded.
     * @param status The status of forwarding.
     */
    event void forwardingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr,
            error_t status
    );
}
