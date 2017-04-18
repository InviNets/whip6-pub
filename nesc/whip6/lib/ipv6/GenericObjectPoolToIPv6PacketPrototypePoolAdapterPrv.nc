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
 * An adapter transforming an object pool
 * into a generic pool of IPv6 packet prototypes.
 *
 * @author Konrad Iwanicki
 */
generic module GenericObjectPoolToIPv6PacketPrototypePoolAdapterPrv()
{
    provides interface IPv6PacketAllocator;
    uses interface ObjectAllocator<whip6_ipv6_packet_t> @exactlyonce();
}
implementation
{
    command inline whip6_ipv6_packet_t * IPv6PacketAllocator.allocIPv6Packet()
    {
        return call ObjectAllocator.allocate();
    }

    command inline void IPv6PacketAllocator.freeIPv6Packet(
            whip6_ipv6_packet_t * packet
    )
    {
        call ObjectAllocator.free(packet);
    }
}
