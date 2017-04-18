/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucString.h>
#include <ieee154/ucIeee154Ipv6InterfaceStateManipulation.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>



/**
 * Checks if a given IPv6 address is in an array
 * of IPv6 addresses.
 * @param addr The address to check.
 * @param addrArrPtr The array of addresses.
 * @param addrArrLen The length of the array.
 * @return Nonzero if the address is
 *   in the array or zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsInArrayOfGenericInterfaceAddrs(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addrArrPtr,
        ipv6_net_iface_addr_count_t addrArrLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Finds the lowest-scope address whose scope is not lower
 * than a given one in an array of IPv6 addresses.
 * @param idAddr An input address.
 * @param outAddr A buffer for the found address.
 * @param addrArrPtr The array of addresses.
 * @param addrArrLen The length of the array.
 * @param scopeLimit The lower limit on the scope.
 * @return The scope of the address found or
 *   IPV6_ADDRESS_SCOPE_MAX_RESERVED if no apppropriate
 *   address was found.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX ipv6_addr_scope_t whip6_ipv6AddrFindBestInArrayOfGenericInterfaceAddrs(
        ipv6_addr_t MCS51_STORED_IN_RAM const * inAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM * outAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addrArrPtr,
        ipv6_net_iface_addr_count_t addrArrLen,
        ipv6_addr_scope_t scopeLimit
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is on the list of
 * unicast addresses associated with a given interface.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address is on the list of
 *   the interface or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrBelongsToGenericUnicastAddrListOfInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is on the list of
 * multicast addresses associated with a given interface.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address is on the list of
 *   the interface or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrBelongsToGenericMulticastAddrListOfInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is one of the
 * addresses specific to a loopback interface.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address is one of the
 *   specific addresses or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrBelongsLoopbackSpecificAddrsOfInterface(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is one of the
 * addresses specific to an 802.15.4 interface.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address is one of the
 *   specific addresses or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrBelongsIeee154SpecificAddrsOfInterface(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrIsInArrayOfGenericInterfaceAddrs(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addrArrPtr,
        ipv6_net_iface_addr_count_t addrArrLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if (addrArrPtr == NULL)
    {
        return 0;
    }
    for (; addrArrLen > 0; --addrArrLen)
    {
        if (whip6_shortMemCmp(
                (uint8_t MCS51_STORED_IN_RAM const * )addr,
                (uint8_t MCS51_STORED_IN_RAM const * )addrArrPtr,
                sizeof(ipv6_addr_t)) == 0)
        {
            return 1;
        }
        ++addrArrPtr;
    }
    return 0;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX ipv6_addr_scope_t whip6_ipv6AddrFindBestInArrayOfGenericInterfaceAddrs(
        ipv6_addr_t MCS51_STORED_IN_RAM const * inAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM * outAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addrArrPtr,
        ipv6_net_iface_addr_count_t addrArrLen,
        ipv6_addr_scope_t scopeLimit
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM const *   bestAddr;
    ipv6_addr_scope_t                         bestScope;
    uint8_t                                   bestPrefix;

    bestScope = IPV6_ADDRESS_SCOPE_MAX_RESERVED;
    if (addrArrPtr != NULL)
    {
        bestAddr = NULL;
        bestPrefix = 0;
        for (; addrArrLen > 0; --addrArrLen)
        {
            ipv6_addr_scope_t   currScope;

            currScope = whip6_ipv6AddrGetScope(addrArrPtr);
            if (currScope >= scopeLimit && currScope <= bestScope)
            {
                if (bestScope == currScope)
                {
                    uint8_t prefMatch;

                    prefMatch =
                            whip6_ipv6AddrGetCommonPrefixLengthInBytes(
                                    inAddr,
                                    addrArrPtr
                            );
                    if (prefMatch > bestPrefix)
                    {
                        bestAddr = addrArrPtr;
                    }
                }
                else
                {
                    bestScope = currScope;
                    bestAddr = addrArrPtr;
                }
            }
            ++addrArrPtr;
        }
        if (bestAddr != NULL)
        {
            whip6_shortMemCpy(
                    (uint8_t MCS51_STORED_IN_RAM const * )&(bestAddr->data8[0]),
                    (uint8_t MCS51_STORED_IN_RAM * )&(outAddr->data8[0]),
                    sizeof(ipv6_addr_t)
            );
        }
    }
    return bestScope;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrBelongsToGenericUnicastAddrListOfInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_ipv6AddrIsInArrayOfGenericInterfaceAddrs(
            addr,
            ifaceState->unicastAddrArrPtr,
            ifaceState->unicastAddrArrLen
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrBelongsToGenericMulticastAddrListOfInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_ipv6AddrIsInArrayOfGenericInterfaceAddrs(
            addr,
            ifaceState->multicastAddrArrPtr,
            ifaceState->multicastAddrArrLen
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrBelongsLoopbackSpecificAddrsOfInterface(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_ipv6AddrIsLoopback(addr);
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ipv6AddrBelongsIeee154SpecificAddrsOfInterface(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_ipv6AddrIsAutoconfiguredLinkLocalAddressOfIeee154Interface(
            ifaceState,
            addr
    );
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6AddrBelongsToInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (addr->data8[0] == 0xff)
    {
        // A multicast address.
        if (whip6_ipv6AddrIsAllNodesMulticast(addr) ||
                whip6_ipv6AddrIsAllRoutersMulticast(addr))
        {
            return 1;
        }
        if (whip6_ipv6AddrBelongsToGenericMulticastAddrListOfInterface(ifaceState, addr))
        {
            return 1;
        }
    }
    else
    {
        // A unicast address.
        if (whip6_ipv6AddrBelongsToGenericUnicastAddrListOfInterface(ifaceState, addr))
        {
            return 1;
        }
    }
    switch ((ifaceState->indexAndType & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK) >>
            WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_SHIFT)
    {
    case WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_LOOPBACK:
        return whip6_ipv6AddrBelongsLoopbackSpecificAddrsOfInterface(
                addr
        );
    case WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_IEEE154:
        return whip6_ipv6AddrBelongsIeee154SpecificAddrsOfInterface(
                (ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const *)ifaceState,
                addr
        );
    }
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6InterfaceGetBestSrcAddrForDstAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_addr_scope_t   srcScope;
    ipv6_addr_scope_t   dstScope;

    if (whip6_ipv6AddrIsUndefined(dstAddr))
    {
        return 0;
    }
    dstScope = whip6_ipv6AddrGetScope(dstAddr);
    if (dstScope == IPV6_ADDRESS_SCOPE_LINK_LOCAL)
    {
        switch ((ifaceState->indexAndType & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK) >>
                WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_SHIFT)
        {
        case WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_LOOPBACK:
            whip6_ipv6AddrSetLoopbackAddr(
                    srcAddr
            );
            return 1;
        case WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_IEEE154:
            whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceBest(
                    (ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const *)ifaceState,
                    srcAddr
            );
            return 1;
        }
    }
    srcScope =
            whip6_ipv6AddrFindBestInArrayOfGenericInterfaceAddrs(
                    dstAddr,
                    srcAddr,
                    ifaceState->unicastAddrArrPtr,
                    ifaceState->unicastAddrArrLen,
                    dstScope
            );
    return srcScope == IPV6_ADDRESS_SCOPE_MAX_RESERVED ? 0 : 1;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6InterfaceAssociateUnicastAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM * dstAddr;

    if (ifaceState->unicastAddrArrLen >= maxAddrSlots)
    {
        return NULL;
    }
    dstAddr = &(ifaceState->unicastAddrArrPtr[ifaceState->unicastAddrArrLen]);
    ++ifaceState->unicastAddrArrLen;
    whip6_ipv6AddrSetUndefinedAddr(dstAddr);
    return dstAddr;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6InterfaceAssociateMulticastAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM * dstAddr;

    if (ifaceState->multicastAddrArrLen >= maxAddrSlots)
    {
        return NULL;
    }
    dstAddr = &(ifaceState->multicastAddrArrPtr[ifaceState->multicastAddrArrLen]);
    ++ifaceState->multicastAddrArrLen;
    whip6_ipv6AddrSetUndefinedAddr(dstAddr);
    return dstAddr;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6InterfaceVerifyUnicastAddrs(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM *   freeAddrSlot;
    ipv6_addr_t MCS51_STORED_IN_RAM *   currAddrSlot;
    uint8_t                             i, j;

    freeAddrSlot = &(ifaceState->unicastAddrArrPtr[0]);
    currAddrSlot = freeAddrSlot;
    for (i = 0, j = 0; i < maxAddrSlots; ++i)
    {
        if (! whip6_ipv6AddrIsUndefined(currAddrSlot) &&
                ! whip6_ipv6AddrIsMulticast(currAddrSlot))
        {
            if (i > j)
            {
                whip6_shortMemCpy(
                        (uint8_t MCS51_STORED_IN_RAM const * )&(currAddrSlot->data8[0]),
                        (uint8_t MCS51_STORED_IN_RAM * )&(freeAddrSlot->data8[0]),
                        sizeof(ipv6_addr_t)
                );
            }
            ++freeAddrSlot;
            ++j;
        }
        ++currAddrSlot;
    }
    ifaceState->unicastAddrArrLen = j;
    return i - j;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6InterfaceVerifyMulticastAddrs(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM *   freeAddrSlot;
    ipv6_addr_t MCS51_STORED_IN_RAM *   currAddrSlot;
    uint8_t                             i, j;

    freeAddrSlot = &(ifaceState->multicastAddrArrPtr[0]);
    currAddrSlot = freeAddrSlot;
    for (i = 0, j = 0; i < maxAddrSlots; ++i)
    {
        if (! whip6_ipv6AddrIsUndefined(currAddrSlot) &&
                whip6_ipv6AddrIsMulticast(currAddrSlot))
        {
            if (i > j)
            {
                whip6_shortMemCpy(
                        (uint8_t MCS51_STORED_IN_RAM const * )&(currAddrSlot->data8[0]),
                        (uint8_t MCS51_STORED_IN_RAM * )&(freeAddrSlot->data8[0]),
                        sizeof(ipv6_addr_t)
                );
            }
            ++freeAddrSlot;
            ++j;
        }
        ++currAddrSlot;
    }
    ifaceState->multicastAddrArrLen = j;
    return i - j;
}
