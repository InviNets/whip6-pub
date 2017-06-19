/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

generic configuration HalEventCountPub(uint32_t pollingInterval) {
    provides interface EventCount as EvCntA;
    provides interface EventCount as EvCntB;

    uses interface EventCountConfig as EvCntAConfig;
    uses interface EventCountConfig as EvCntBConfig;

    uses interface CC26xxPin as PinA;
    uses interface CC26xxPin as PinB;
}

implementation {
    components new HalEventCountPrv(pollingInterval) as Prv;
    EvCntA = Prv.EvCntA;
    EvCntB = Prv.EvCntB;
    EvCntAConfig = Prv.EvCntAConfig;
    EvCntBConfig = Prv.EvCntBConfig;
    Prv.PinA = PinA;
    Prv.PinB = PinB;

    components new CC26xxTimerPub() as Timer;
    Prv.CC26xxTimer -> Timer;

    components CC26xxPowerDomainsPub as PowerDomains;
    Prv.PowerDomain -> PowerDomains.PeriphDomain;

    components new PlatformTimerMilliPub();
    Prv.Timer -> PlatformTimerMilliPub;

    components new HalAskBeforeSleepPub();
    Prv.AskBeforeSleep -> HalAskBeforeSleepPub;
}
