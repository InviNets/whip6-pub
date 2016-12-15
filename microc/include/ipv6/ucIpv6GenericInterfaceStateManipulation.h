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

#ifndef __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_MANIPULATION_H__
#define __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_MANIPULATION_H__

#include <base/ucError.h>
#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the functionality for manipulating
 * the generic IPv6-related state of a network interface.
 */

#define whip6_ipv6InterfaceGetNextInterface(ifaceState) ((ifaceState)->next)
#define whip6_ipv6InterfaceSetNextInterface(ifaceState, pnext) do { (ifaceState)->next = (pnext); } while (0)
#define whip6_ipv6InterfaceGetPrevInterface(ifaceState) ((ifaceState)->prev)
#define whip6_ipv6InterfaceSetPrevInterface(ifaceState, pprev) do { (ifaceState)->prev = (pprev); } while (0)
#define whip6_ipv6InterfaceGetIndex(ifaceState) (((ifaceState)->indexAndType & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_MASK) >> WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_SHIFT)
#define whip6_ipv6InterfaceSetIndex(ifaceState, idx) do { \
    (ifaceState)->indexAndType &= ~(uint8_t)WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_MASK; \
    (ifaceState)->indexAndType |= ((idx) << WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_SHIFT) & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_MASK; \
} while (0)
#define whip6_ipv6InterfaceGetType(ifaceState) (((ifaceState)->indexAndType & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK) >> WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_SHIFT)
#define whip6_ipv6InterfaceSetType(ifaceState, tp) do { \
    (ifaceState)->indexAndType &= ~(uint8_t)WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK; \
    (ifaceState)->indexAndType |= ((tp) << WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_SHIFT) & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK; \
} while (0)
#define whip6_ipv6InterfaceClearFlags(ifaceState) do { (ifaceState)->flags = 0; } while (0)
#define whip6_ipv6InterfaceSetOnFlag(ifaceState) do { (ifaceState)->flags |= WHIP6_IPV6_NET_IFACE_GENERIC_STATE_FLAG_IS_ON; } while (0)
#define whip6_ipv6InterfaceHasOnFlag(ifaceState) (((ifaceState)->flags & WHIP6_IPV6_NET_IFACE_GENERIC_STATE_FLAG_IS_ON) != 0)
#define whip6_ipv6InterfaceSetUnicastAddrArray(ifaceState, ap, al) do { \
    (ifaceState)->unicastAddrArrPtr = (ap); \
    (ifaceState)->unicastAddrArrLen = (al); \
} while (0);
#define whip6_ipv6InterfaceSetMulticastAddrArray(ifaceState, ap, al) do { \
    (ifaceState)->multicastAddrArrPtr = (ap); \
    (ifaceState)->multicastAddrArrLen = (al); \
} while (0);


/**
 * Checks if a given IPv6 address belongs to
 * a given interface. If the interface is down,
 * the result is always false.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address belongs to
 *   the interface or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6AddrBelongsToInterface(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the best source IPv6 address associated
 * with a given interface for a given destination IPv6
 * address.
 * @param ifaceState The interface.
 * @param srcAddr A buffer for the source address.
 * @param dstAddr The destination address.
 * @return Nonzero if the source buffer contains a
 *   valid address or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6InterfaceGetBestSrcAddrForDstAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Associates an undefined IPv6 unicast address with
 * a given interface as the last address of the interface.
 * @param ifaceState The interface.
 * @param maxAddrSlots The maximal number of
 *   address slots for the interface.
 * @return A pointer to the associated address or NULL
 *   if there is no free slot in which the address
 *   could be placed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6InterfaceAssociateUnicastAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Associates an undefined IPv6 multicast address with
 * a given interface as the last address of the interface.
 * @param ifaceState The interface.
 * @param maxAddrSlots The maximal number of
 *   address slots for the interface.
 * @return A pointer to the associated address or NULL
 *   if there is no free slot in which the address
 *   could be placed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6InterfaceAssociateMulticastAddr(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Clears a list of associated unicast addresses
 * such that all invalid addresses are removed.
 * @param ifaceState The interface.
 * @param maxAddrSlots The maximal number of
 *   address slots for the interface.
 * @return The number of removed addresses.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6InterfaceVerifyUnicastAddrs(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Clears a list of associated multicast addresses
 * such that all invalid addresses are removed.
 * @param ifaceState The interface.
 * @param maxAddrSlots The maximal number of
 *   address slots for the interface.
 * @return The number of removed addresses.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6InterfaceVerifyMulticastAddrs(
        ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * ifaceState,
        uint8_t maxAddrSlots
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#include <ipv6/detail/ucIpv6GenericInterfaceStateManipulationImpl.h>

#endif /* __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_TYPES_H__ */
