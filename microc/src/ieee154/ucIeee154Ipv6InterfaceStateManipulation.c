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

#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>
#include <ieee154/ucIeee154Ipv6InterfaceStateManipulation.h>
#include <ipv6/ucIpv6AddressManipulation.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6AddrIsAutoconfiguredLinkLocalAddressOfIeee154Interface(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    int8_t                                i;

    if (! whip6_ipv6AddrIsLinkLocal(addr))
    {
        goto PREFIX_NOT_EQUAL;
    }
    if ((ifaceState->genericState.flags & WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR) == 0)
    {
        goto SHORT_NOT_EQUAL;
    }
    addrBytePtr = &(addr->data8[15]);
    if (*addrBytePtr != ifaceState->ieee154ShrtAddr.data[0])
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != (ifaceState->ieee154ShrtAddr.data[1]))
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != 0x00)
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != 0xfe)
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != 0xff)
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != 0x00)
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != ifaceState->ieee154PanId.data[0])
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    if (*addrBytePtr != (ifaceState->ieee154PanId.data[1] & ~(uint8_t)0x02))
    {
        goto SHORT_NOT_EQUAL;
    }
    --addrBytePtr;
    goto ADDRESS_EQUAL;

SHORT_NOT_EQUAL:
    addrBytePtr = &(addr->data8[8]);
    if (*addrBytePtr != (ifaceState->ieee154ExtAddr.data[7] ^ 0x02))
    {
        goto LONG_NOT_EQUAL;
    }
    ++addrBytePtr;
    for (i = 6; i >= 0; --i)
    {
        if (*addrBytePtr != ifaceState->ieee154ExtAddr.data[i])
        {
            goto LONG_NOT_EQUAL;
        }
        ++addrBytePtr;
    }

ADDRESS_EQUAL:
    return 1;

LONG_NOT_EQUAL:
PREFIX_NOT_EQUAL:
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceExt(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    whip6_ipv6AddrSetLinkLocalPrefix(addr);
    whip6_ipv6AddrFillSuffixWithIeee154AddrExt(
            addr,
            &ifaceState->ieee154ExtAddr
    );
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceShrt(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if ((ifaceState->genericState.flags & WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR) == 0)
    {
        return 0;
    }
    whip6_ipv6AddrSetLinkLocalPrefix(addr);
    whip6_ipv6AddrFillSuffixWithIeee154AddrShort(
            addr,
            &ifaceState->ieee154ShrtAddr,
            &ifaceState->ieee154PanId
    );
    return 1;
}
