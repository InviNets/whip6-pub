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
 * A generic implementation of
 * a computer of Internet checksums.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIPv6ChecksumComputerPub()
{
    provides
    {
        interface IPv6ChecksumComputer;
    }
}
implementation
{
    enum
    {
        CLIENT_IDX = unique("GenericIPv6ChecksumComputerMuxPrv::Client"),
    };

    components GenericIPv6ChecksumComputerMuxPrv as MuxPrv;

    IPv6ChecksumComputer = MuxPrv.IPv6ChecksumComputer[CLIENT_IDX];
}
