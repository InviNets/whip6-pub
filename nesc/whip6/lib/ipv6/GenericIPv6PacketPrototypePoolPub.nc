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
 * A generic pool of IPv6 packet prototypes.
 *
 * @param num_packets The number of packet
 *   prototypes in the pool. Must be positive.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIPv6PacketPrototypePoolPub(
        size_t num_packets
)
{
    provides
    {
        interface Init @exactlyonce();
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
    components new GenericObjectPoolPub(whip6_ipv6_packet_t, num_packets) as ObjPoolPrv;
    components new GenericObjectPoolToIPv6PacketPrototypePoolAdapterPrv() as AdapterPrv;

    Init = ObjPoolPrv;
    IPv6PacketAllocator = AdapterPrv;

    AdapterPrv.ObjectAllocator -> ObjPoolPrv;

    ObjPoolPrv.NumSuccessfulAllocsStat = NumSuccessfulPacketPrototypeAllocsStat;
    ObjPoolPrv.NumFailedAllocsStat = NumFailedPacketPrototypeAllocsStat;
    ObjPoolPrv.NumDisposalsStat = NumPacketPrototypeDisposalsStat;
}
