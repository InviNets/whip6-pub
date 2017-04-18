/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_DETAIL_IPV6_ADDRESS_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_IPV6_DETAIL_IPV6_ADDRESS_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_IPV6_IPV6_ADDRESS_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__ */

#include <base/ucString.h>


WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsUndefined(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t                               i;

    addrBytePtr = &(addr->data8[0]);
    for (i = 0; i < 16; ++i)
    {
        if (*addrBytePtr != 0x00)
        {
            return 0;
        }
        ++addrBytePtr;
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsLoopback(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t                               i;

    addrBytePtr = &(addr->data8[0]);
    for (i = 0; i < 15; ++i)
    {
        if (*addrBytePtr != 0x00)
        {
            return 0;
        }
        ++addrBytePtr;
    }
    if (*addrBytePtr != 0x01)
    {
        return 0;
    }
    return 1;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrIsMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return addr->data8[0] == 0xff;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsAllNodesMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrPtr;
    uint8_t                               addrCnt;

    if (addr->data8[0] != 0xff ||
            addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES - 1] != 0x01 ||
            (addr->data8[1] != IPV6_ADDRESS_SCOPE_INTERFACE_LOCAL &&
                    addr->data8[1] != IPV6_ADDRESS_SCOPE_LINK_LOCAL))
    {
        return 0;
    }
    addrPtr = &(addr->data8[2]);
    for (addrCnt = IPV6_ADDRESS_LENGTH_IN_BYTES - 3; addrCnt > 0; --addrCnt)
    {
        if (*addrPtr != 0x00)
        {
            return 0;
        }
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsAllRoutersMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrPtr;
    uint8_t                               addrCnt;

    if (addr->data8[0] != 0xff ||
            addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES - 1] != 0x02 ||
            (addr->data8[1] != IPV6_ADDRESS_SCOPE_INTERFACE_LOCAL &&
                    addr->data8[1] != IPV6_ADDRESS_SCOPE_LINK_LOCAL &&
                    addr->data8[1] != IPV6_ADDRESS_SCOPE_SITE_LOCAL))
    {
        return 0;
    }
    addrPtr = &(addr->data8[2]);
    for (addrCnt = IPV6_ADDRESS_LENGTH_IN_BYTES - 3; addrCnt > 0; --addrCnt)
    {
        if (*addrPtr != 0x00)
        {
            return 0;
        }
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsLinkLocal(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t                               i;

    addrBytePtr = &(addr->data8[0]);
    if (*addrBytePtr != 0xfe)
    {
        return 0;
    }
    ++addrBytePtr;
    if (*addrBytePtr != 0x80)
    {
        return 0;
    }
    ++addrBytePtr;
    for (i = 6; i > 0; --i)
    {
        if (*addrBytePtr != 0x00)
        {
            return 0;
        }
        ++addrBytePtr;
    }
    return 1;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrIsUniqueLocal(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if ((addr->data8[0] & 0xfe) == 0xfc)
    {
        return 1;
    }
    return 0;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrGetCommonPrefixLengthInBytes(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr1,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   ptr1;
    uint8_t MCS51_STORED_IN_RAM const *   ptr2;
    uint8_t                               i;

    ptr1 = &(addr1->data8[0]);
    ptr2 = &(addr2->data8[0]);
    for (i = 0; i < IPV6_ADDRESS_LENGTH_IN_BYTES; ++i)
    {
        if (*ptr1 != *ptr2)
        {
            break;
        }
        ++ptr1;
        ++ptr2;
    }
    return i;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6AddrSetLinkLocalPrefix(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *   addrBytePtr;
    uint8_t                         i;

    addrBytePtr = &(addr->data8[0]);
    *addrBytePtr = 0xfe;
    ++addrBytePtr;
    *addrBytePtr = 0x80;
    ++addrBytePtr;
    for (i = 6; i > 0; --i)
    {
        *addrBytePtr = 0x00;
        ++addrBytePtr;
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6AddrSetLoopbackAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *   addrBytePtr;
    uint8_t                         i;

    addrBytePtr = &(addr->data8[0]);
    for (i = 15; i > 0; --i)
    {
        *addrBytePtr = 0x00;
        ++addrBytePtr;
    }
    *addrBytePtr = 0x01;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6AddrSetUndefinedAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    whip6_shortMemSet((uint8_t MCS51_STORED_IN_RAM *)&(addr->data8[0]), 0x00, 16);
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6AddrSetAllNodesLinkLocalAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *   addrBytePtr;
    uint8_t                         i;

    addrBytePtr = &(addr->data8[0]);
    *addrBytePtr = 0xff;
    ++addrBytePtr;
    *addrBytePtr = IPV6_ADDRESS_SCOPE_LINK_LOCAL;
    ++addrBytePtr;
    for (i = IPV6_ADDRESS_LENGTH_IN_BYTES - 3; i > 0; --i)
    {
        *addrBytePtr = 0x00;
        ++addrBytePtr;
    }
    *addrBytePtr = 0x01;
}



#endif /* __WHIP6_MICROC_IPV6_DETAIL_IPV6_ADDRESS_MANIPULATION_IMPL_H__ */
