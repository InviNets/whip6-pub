/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_H__

#include <ieee154/ucIeee154Ipv6InterfaceStateTypes.h>

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains manipulation functions for
 * the IPv6-related state of a network interface
 * running on top IEEE 802.15.4.
 */


#define whip6_ipv6InterfaceSetShortIeee154AddrFlag(ifaceState) do { (ifaceState)->flags |= WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR; } while (0)
#define whip6_ipv6InterfaceClearShortIeee154AddrFlag(ifaceState) do { (ifaceState)->flags &= ~(uint8_t)WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR; } while (0)
#define whip6_ipv6InterfaceHasShortIeee154AddrFlag(ifaceState) (((ifaceState)->flags & WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR) != 0)


/**
 * Checks if a given IPv6 address is the autoconfigured
 * link-local unicast address of a given IEEE 802.15.4
 * network interface.
 * @param ifaceState The interface to check.
 * @param addr The address to check.
 * @return Nonzero if the address belongs to
 *   the interface or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6AddrIsAutoconfiguredLinkLocalAddressOfIeee154Interface(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Fetches the link-local unicast address of a given
 * IEEE 802.15.4 interface based on the extended
 * IEEE 802.15.4 address.
 * @param ifaceState The interface.
 * @param addr A buffer for the address.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceExt(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Fetches the link-local unicast address of a given
 * IEEE 802.15.4 interface based on the short
 * IEEE 802.15.4 address (if it exists).
 * @param ifaceState The interface.
 * @param addr A buffer for the address.
 * @return Nonzero if the short address exists, in which
 *   case the buffer will contain a valid IPv6 address,
 *   or zero if the short address does not exist,
 *   in which case the buffer remains unmodified.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceShrt(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Fetches the best link-local unicast address of
 * a given IEEE 802.15.4 interface, that is,
 * the short address if it is present, or the
 * extended one otherwise.
 * @param ifaceState The interface.
 * @param addr A buffer for the address.
 * @return The IEEE 802.15.4 address type used.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrGetAutoconfiguredLinkLocalAddressOfIeee154InterfaceBest(
        ipv6_net_iface_ieee154_state_t MCS51_STORED_IN_RAM const * ifaceState,
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



#include <ieee154/detail/ucIeee154Ipv6InterfaceStateManipulationImpl.h>

#endif /* __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_MANIPULATION_H__ */
