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

#ifndef __WHIP6_MICROC_IPV6_IPV6_PACKET_ALLOCATION_H__
#define __WHIP6_MICROC_IPV6_IPV6_PACKET_ALLOCATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 packet allocation
 * routines.
 */

#include <ipv6/ucIpv6PacketTypes.h>

/**
 * Allocates an IPv6 packet with a given payload.
 * @param payloadLength The length of the payload,
 *   that is, the portion of the packet without
 *   the basic IPv6 header.
 * @return A pointer to the allocated packet or
 *   NULL if the allocation has failed.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_ipv6AllocatePacket(
        ipv6_payload_length_t payloadLength
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Frees an IPv6 packet.
 * @param packet A packet to be freed.
 *   Must not be NULL.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6FreePacket(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


#include <ipv6/detail/ucIpv6PacketAllocationImpl.h>

#endif /* __WHIP6_MICROC_IPV6_IPV6_PACKET_ALLOCATION_H__ */
