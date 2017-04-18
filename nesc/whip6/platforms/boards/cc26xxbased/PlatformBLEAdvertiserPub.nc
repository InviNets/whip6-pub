/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

generic configuration PlatformBLEAdvertiserPub() {
    provides interface RawBLEAdvertiser;

    uses interface StatsIncrementer<uint8_t> as NumSuccessfulBLEAdvTXStat;
}

implementation {
    enum {
        USER_ID = unique("PlatformBLEAdvertiserPrv"),
    };

    components PlatformBLEAdvertiserPrv as Prv;
    RawBLEAdvertiser = Prv.RawBLEAdvertiser[USER_ID];
    NumSuccessfulBLEAdvTXStat = Prv.NumSuccessfulBLEAdvTXStat;
}
