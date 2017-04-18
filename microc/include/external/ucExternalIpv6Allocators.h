/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_ALLOCATORS_H__
#define __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_ALLOCATORS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains prototypes of allocator functions
 * for IPv6 types in microc.
 */

#include <ipv6/ucIpv6PacketTypes.h>


/**
 * Allocates an IPv6 packet.
 * @return A pointer to the allocated packet,
 *   or NULL if allocation failed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_ipv6AllocNewIPv6Packet(
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Frees an allocated IPv6 packet.
 * @param packetPtr A pointer to the packet
 *   to be freed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6FreeExistingIPv6Packet(
        ipv6_packet_t MCS51_STORED_IN_RAM * packetPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_ALLOCATORS_H__ */
