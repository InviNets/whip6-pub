/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include "BaseCompileTimeConfig.h"



/**
 * A generic allocator of I/O vector elements.
 *
 * @author Konrad Iwanicki
 */
configuration GenericIOVElementAllocatorPub
{
    provides
    {
        interface IOVAllocator;
    }
    uses
    {
        interface StatsIncrementer<uint8_t> as NumSuccessfulIOVElementAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedIOVElementAllocsStat;
        interface StatsIncrementer<uint8_t> as NumIOVElementDisposalsStat;
    }
}
implementation
{
    components IOVAllocatorPub as MainAllocPrv;
    components new GenericFixedSizeIOVElementPoolPub(
            WHIP6_BASE_IOV_MAX_ELEMENT_SIZE,
            WHIP6_BASE_IOV_MAX_CONCURRENT_ELEMENTS
    ) as RealAllocPrv;

    IOVAllocator = RealAllocPrv;

    MainAllocPrv.PlatformSpecificInit -> RealAllocPrv;
    MainAllocPrv.PlatformSpecificAllocator -> RealAllocPrv;

    RealAllocPrv.NumSuccessfulIOVElementAllocsStat = NumSuccessfulIOVElementAllocsStat;
    RealAllocPrv.NumFailedIOVElementAllocsStat = NumFailedIOVElementAllocsStat;
    RealAllocPrv.NumIOVElementDisposalsStat = NumIOVElementDisposalsStat;
}
