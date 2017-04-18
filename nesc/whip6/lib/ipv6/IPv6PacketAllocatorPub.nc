/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <external/ucExternalIpv6Allocators.h>
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * A platform-independent packet allocator
 * for IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
module IPv6PacketAllocatorPub
{
    provides
    {
        interface Init @exactlyonce();
    }
    uses
    {
        interface Init as PlatformSpecificInit @atmostonce();
        interface IPv6PacketAllocator as PlatformSpecificAllocator @atmostonce();
    }
}
implementation
{
    command inline error_t Init.init()
    {
        return call PlatformSpecificInit.init();
    }

    default command inline error_t PlatformSpecificInit.init()
    {
        return SUCCESS;
    }

    default command inline whip6_ipv6_packet_t * PlatformSpecificAllocator.allocIPv6Packet()
    {
        return NULL;
    }

    default command inline void PlatformSpecificAllocator.freeIPv6Packet(whip6_ipv6_packet_t * packet)
    {
    }

    whip6_ipv6_packet_t * whip6_ipv6AllocNewIPv6Packet(
    ) @C() @spontaneous() // __attribute__((banked))
    {
        return call PlatformSpecificAllocator.allocIPv6Packet();
    }

    void whip6_ipv6FreeExistingIPv6Packet(
            whip6_ipv6_packet_t * packetPtr
    ) @C() @spontaneous() // __attribute__((banked))
    {
        call PlatformSpecificAllocator.freeIPv6Packet(packetPtr);
    }

}
