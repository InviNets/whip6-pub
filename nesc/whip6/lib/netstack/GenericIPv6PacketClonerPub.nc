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

