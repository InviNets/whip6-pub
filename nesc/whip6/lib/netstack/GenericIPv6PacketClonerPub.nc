/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * A generic implementation of
 * a cloner for IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIPv6PacketClonerPub()
{
    provides
    {
        interface IPv6PacketCloner;
    }
}
implementation
{
    enum
    {
        CLIENT_IDX = unique("GenericIPv6PacketClonerMuxPrv::Client"),
    };

    components GenericIPv6PacketClonerMuxPrv as MuxPrv;

    IPv6PacketCloner = MuxPrv.IPv6PacketCloner[CLIENT_IDX];
}
