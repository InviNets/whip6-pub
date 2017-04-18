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

configuration PlatformBLEAdvertiserPrv {
    provides interface RawBLEAdvertiser[uint8_t client];
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulBLEAdvTXStat;
}

implementation {
    components HalRadioPub as Hal;
    NumSuccessfulBLEAdvTXStat = Hal.NumSuccessfulBLEAdvTXStat;

    components new
        RawBLEAdvertiserMuxPub(uniqueCount("PlatformBLEAdvertiserPrv")) as Mux;
    Mux.LowAdvertiser -> Hal.RawBLEAdvertiser;
    RawBLEAdvertiser = Mux.RawBLEAdvertiser;

    components PlatformBLEInitPrv;
}
