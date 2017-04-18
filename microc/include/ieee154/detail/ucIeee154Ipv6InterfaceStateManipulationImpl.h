/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceBest(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if (whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceShrt(ifaceState, addr))
    {
        return IEEE154_ADDR_MODE_SHORT;
    }
    whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceExt(ifaceState, addr);
    return IEEE154_ADDR_MODE_EXT;
}


#endif /* __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_IMPL_H__ */
