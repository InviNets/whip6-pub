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
