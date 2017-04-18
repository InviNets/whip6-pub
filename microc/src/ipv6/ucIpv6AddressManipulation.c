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




WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_addr_scope_t whip6_ipv6AddrGetScope(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (whip6_ipv6AddrIsMulticast(addr))
    {
        return (addr->data8[1] & 0xf);
    }
    else
    {
        if (whip6_ipv6AddrIsUndefined(addr))
        {
            return IPV6_ADDRESS_SCOPE_INTERFACE_LOCAL;
        }
        if (whip6_ipv6AddrIsUniqueLocal(addr))
        {
            return IPV6_ADDRESS_SCOPE_SITE_LOCAL;
        }
        if (whip6_ipv6AddrIsLoopback(addr) || whip6_ipv6AddrIsLinkLocal(addr))
        {
            return IPV6_ADDRESS_SCOPE_LINK_LOCAL;
        }
        return IPV6_ADDRESS_SCOPE_GLOBAL;
    }
}
