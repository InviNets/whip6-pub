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
 * constant extended IEEE 802.15.4 address.
 *
 * @param msb_0  The first (most significant) byte of the address.
 * @param msb_1  The second byte of the address.
 * @param msb_2  The third byte of the address.
 * @param msb_3  The fourth byte of the address.
 * @param msb_4  The fifth byte of the address.
 * @param msb_5  The sixth byte of the address.
 * @param msb_6  The seventh byte of the address.
 * @param msb_7  The eighth (least significant) byte of the address.
 *
 * @author Konrad Iwanicki
 */
generic module GenericLoWPANDefaultRouteViaConstIeee154ExtAddrProviderPub(
        uint8_t msb_0,
        uint8_t msb_1,
        uint8_t msb_2,
        uint8_t msb_3,
        uint8_t msb_4,
        uint8_t msb_5,
        uint8_t msb_6,
        uint8_t msb_7
)
{
    provides interface LoWPANSimpleRoutingStrategy;
}
implementation
{
    void setAddress(whip6_ieee154_addr_t * addr)
    {
        uint8_t_xdata * addrPtr = &(addr->vars.ext.data[0]);
        addr->mode = IEEE154_ADDR_MODE_EXT;
        *addrPtr = msb_7;
        ++addrPtr;
        *addrPtr = msb_6;
        ++addrPtr;
        *addrPtr = msb_5;
        ++addrPtr;
        *addrPtr = msb_4;
        ++addrPtr;
        *addrPtr = msb_3;
        ++addrPtr;
        *addrPtr = msb_2;
        ++addrPtr;
        *addrPtr = msb_1;
        ++addrPtr;
        *addrPtr = msb_0;
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

