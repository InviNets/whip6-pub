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

#include <base/ucString.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154AddressTypes.h>



/**
 * A generic implementation of a provider of an IEEE 802.15.4
 * address representing a default route that uses a compile-time
 * constant short IEEE 802.15.4 address.
 *
 * @param shortId The short identifier assigned to the node.
 *
 * @author Konrad Iwanicki
 */
generic module GenericLoWPANDefaultRouteViaConstIeee154ShortAddrProviderPub(
        uint16_t shortId
)
{
    provides interface LoWPANSimpleRoutingStrategy;
}
implementation
{
    void setAddress(whip6_ieee154_addr_t * addr)
    {
        uint8_t_xdata * addrPtr = &(addr->vars.shrt.data[0]);
        addr->mode = IEEE154_ADDR_MODE_SHORT;
        *addrPtr = (uint8_t)shortId;
        ++addrPtr;
        *addrPtr = (uint8_t)(shortId >> 8);
    }

    command void LoWPANSimpleRoutingStrategy.pickFirstRouteLinkLayerAddr(
            whip6_ipv6_out_packet_processing_state_t *outPacket,
            whip6_ipv6_addr_t const *dstAddr,
            whip6_ieee154_addr_t  *llAddr) {
        setAddress(llAddr);
    }

    command void LoWPANSimpleRoutingStrategy.pickNextRouteLinkLayerAddr(
            whip6_ipv6_out_packet_processing_state_t *outPacket,
            whip6_ipv6_addr_t const *dstAddr,
            whip6_ieee154_addr_t const *lastLLAddr,
            error_t lastStatus,
            whip6_ieee154_addr_t  *llAddr) {

        whip6_ieee154AddrAnySetNone(llAddr);
    }
}

