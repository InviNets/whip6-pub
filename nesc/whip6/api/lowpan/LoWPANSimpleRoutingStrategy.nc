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

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>

/**
 * A provider of an IEEE 802.15.4 address for the next hop.
 *
 * @author Przemysław Horban
 */
interface LoWPANSimpleRoutingStrategy
{

    /**
     * Provides an IEEE 802.15.4 address that
     * represents the address of the next hop for this packet.
     * Called when packet is first seen.
     *
     * @param llAddr A buffer that will receive
     *   the address representing the default
     *   route. If there is no such route, the
     *   address will be set to
     *   <tt>IEEE154_ADDR_MODE_NONE</tt>.
     */
    command void pickFirstRouteLinkLayerAddr(
        whip6_ipv6_out_packet_processing_state_t *outPacket,
        whip6_ipv6_addr_t const *dstAddr,
        whip6_ieee154_addr_t  *llAddr);

    /**
     * Provides an IEEE 802.15.4 address that
     * represents the address of the next hop for this packet.
     * Called when forwarding has failed.
     *
     * @param llAddr A buffer that will receive
     *   the address representing the default
     *   route. If there is no such route, the
     *   address will be set to
     *   <tt>IEEE154_ADDR_MODE_NONE</tt>.
    */
    command void pickNextRouteLinkLayerAddr(
        whip6_ipv6_out_packet_processing_state_t *outPacket,
        whip6_ipv6_addr_t const *dstAddr,
        whip6_ieee154_addr_t const *lastLLAddr,
        error_t lastStatus,
        whip6_ieee154_addr_t  *llAddr);
}

