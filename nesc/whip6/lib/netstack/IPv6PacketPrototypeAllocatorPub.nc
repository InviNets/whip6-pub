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
#include "NetStackCompileTimeConfig.h"



/**
 * A platform-specific allocator of
 * IPv6 packet prototypes.
 *
 * @author Konrad Iwanicki
 */
configuration IPv6PacketPrototypeAllocatorPub
{
    provides
    {
        interface IPv6PacketAllocator;
    }
    uses
    {
        interface StatsIncrementer<uint8_t> as NumSuccessfulPacketPrototypeAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedPacketPrototypeAllocsStat;
        interface StatsIncrementer<uint8_t> as NumPacketPrototypeDisposalsStat;
    }
}
implementation
{
    components IPv6PacketAllocatorPub as MainAllocPrv;
    components new GenericIPv6PacketPrototypePoolPub(
            WHIP6_IPV6_MAX_CONCURRENT_PACKETS
    ) as RealAllocPrv;

    IPv6PacketAllocator = RealAllocPrv;

    MainAllocPrv.PlatformSpecificInit -> RealAllocPrv;
    MainAllocPrv.PlatformSpecificAllocator -> RealAllocPrv;
    
    RealAllocPrv.NumSuccessfulPacketPrototypeAllocsStat = NumSuccessfulPacketPrototypeAllocsStat;
    RealAllocPrv.NumFailedPacketPrototypeAllocsStat = NumFailedPacketPrototypeAllocsStat;
    RealAllocPrv.NumPacketPrototypeDisposalsStat = NumPacketPrototypeDisposalsStat;
}
