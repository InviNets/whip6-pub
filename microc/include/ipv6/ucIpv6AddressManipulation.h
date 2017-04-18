/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_ADDRESS_MANIPULATION_H__
#define __WHIP6_MICROC_IPV6_IPV6_ADDRESS_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 address manipulation functionality.
 * For more information, refer to the wikipedia.
 */

#include <ipv6/ucIpv6AddressTypes.h>


/**
 * Checks if a given IPv6 address in an undefined address.
 * @param addr The address to check.
 * @return Zero if the address is not an undefined address,
 *   or a non-zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsUndefined(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address in a loopback address.
 * @param addr The address to check.
 * @return Zero if the address is not a loopback address,
 *   or a non-zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsLoopback(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is a multicast address.
 * @param addr The address to check.
 * @return Zero if the address is not a multicast address,
 *   or a non-zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrIsMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is an all-nodes multicast address.
 * @param addr The address to check.
 * @return Zero if the address is an all-nodes multicast address
 *   or a non-zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsAllNodesMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if a given IPv6 address is an all-routers multicast address.
 * @param addr The address to check.
 * @return Zero if the address is an all-routers multicast address
 *   or a non-zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsAllRoutersMulticast(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if an IPv6 address has a 64-bit
 * prefix denoting the link-local scope.
 * @param addr The address to be checked.
 * @return Nonzero if the address has the
 *   link-local prefix or zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrIsLinkLocal(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks whether a given IPv6 address is a
 * unique local address.
 * @param addr The address to be checked.
 * @return Nonzero if the address is a unique
 *   local address or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ipv6AddrIsUniqueLocal(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the scope of a given IPv6 address.
 * @param addr The address to analyze.
 * @return The scope of the address.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_addr_scope_t whip6_ipv6AddrGetScope(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the length (in bytes) of the common prefix
 * of two IPv6 addresses.
 * @param addr1 The first address.
 * @param addr2 The second address.
 * @return The length of the common prefix: a value
 *   from 0 to IPV6_ADDRESS_LENGTH_IN_BYTES (inclusive).
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6AddrGetCommonPrefixLengthInBytes(
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr1,
        ipv6_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Fills in the 64-bit link-local prefix
 * to the address.
 * @param addr The address.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6AddrSetLinkLocalPrefix(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Sets the address to the loopback address.
 * @param addr The address.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6AddrSetLoopbackAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Sets the address to the undefined address.
 * @param addr The address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6AddrSetUndefinedAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the address to the multicast address representing
 * all link-local nodes.
 * @param addr The address to be set.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6AddrSetAllNodesLinkLocalAddr(
        ipv6_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



#include <ipv6/detail/ucIpv6AddressManipulationImpl.h>

#endif /* __WHIP6_MICROC_IPV6_IPV6_ADDRESS_MANIPULATION_H__ */
