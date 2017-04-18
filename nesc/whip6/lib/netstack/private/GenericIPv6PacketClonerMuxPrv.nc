/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "NetStackCompileTimeConfig.h"



/**
 * A platform-dependent multiplexer for
 * IPv6 packet cloners.
 *
 * @author Konrad Iwanicki
 */
configuration GenericIPv6PacketClonerMuxPrv
{
    provides
    {
        interface IPv6PacketCloner[uint8_t clientIdx];
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = uniqueCount("GenericIPv6PacketClonerMuxPrv::Client"),
    };

    enum
    {
        BYTES_PER_TASK = WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK,
    };

    components BoardStartupPub;
    components new GenericVirtualizedIPv6PacketClonerPub(
            NUM_CLIENTS,
            BYTES_PER_TASK
    ) as ImplPrv;

    BoardStartupPub.InitSequence[0] -> ImplPrv;
    IPv6PacketCloner = ImplPrv;
}
