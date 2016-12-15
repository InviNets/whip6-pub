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




configuration PlatformIOVElementAllocatorPub
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
    components GenericIOVElementAllocatorPub as Generic;
    IOVAllocator = Generic;
    Generic.NumSuccessfulIOVElementAllocsStat = NumSuccessfulIOVElementAllocsStat;
    Generic.NumFailedIOVElementAllocsStat = NumFailedIOVElementAllocsStat;
    Generic.NumIOVElementDisposalsStat = NumIOVElementDisposalsStat;
}

