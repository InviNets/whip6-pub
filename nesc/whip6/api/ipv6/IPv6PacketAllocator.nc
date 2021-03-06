/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6PacketTypes.h>


/**
 * An allocator for IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
interface IPv6PacketAllocator
{
    /**
     * Allocates a new packet.
     * @return A pointer to the allocated packet
     *   or NULL if there is no memory to allocate one.
     */
    command whip6_ipv6_packet_t * allocIPv6Packet();

    /**
     * Frees a previously allocated packet.
     * @param packet A pointer to the packet
     *   to be freed.
     */
    command void freeIPv6Packet(whip6_ipv6_packet_t * packet);
}
