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

#include "BaseCompileTimeConfig.h"



/**
 * A multiplexer for
 * Internet checksum computers.
 *
 * @author Konrad Iwanicki
 */
configuration GenericIPv6ChecksumComputerMuxPrv
{
    provides
    {
        interface IPv6ChecksumComputer[uint8_t clientIdx];
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = uniqueCount("GenericIPv6ChecksumComputerMuxPrv::Client"),
    };

    enum
    {
        BYTES_PER_TASK = WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK,
    };

    components BoardStartupPub;
    components new GenericVirtualizedIPv6ChecksumComputerPub(
            NUM_CLIENTS,
            BYTES_PER_TASK
    ) as ImplPrv;

    BoardStartupPub.InitSequence[0] -> ImplPrv;
    IPv6ChecksumComputer = ImplPrv;
}

