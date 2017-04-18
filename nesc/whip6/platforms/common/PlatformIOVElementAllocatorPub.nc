/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
