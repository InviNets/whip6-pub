/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic configuration HalOutputPWMPub() {
    provides interface OutputPWM as PWMA;
    provides interface OutputPWM as PWMB;

    uses interface OutputPWMConfig as PWMAConfig;
    uses interface OutputPWMConfig as PWMBConfig;

    uses interface CC26xxPin as PinA;
    uses interface CC26xxPin as PinB;
}

implementation {
    components new HalOutputPWMPrv() as Prv;
    PWMA = Prv.PWMA;
    PWMB = Prv.PWMB;
    PWMAConfig = Prv.PWMAConfig;
    PWMBConfig = Prv.PWMBConfig;
    PinA = Prv.PinA;
    PinB = Prv.PinB;

    components new CC26xxTimerPub() as Timer;
    Prv.CC26xxTimer -> Timer;

    components CC26xxPowerDomainsPub as PowerDomains;
    Prv.PowerDomain -> PowerDomains.PeriphDomain;

    components new HalAskBeforeSleepPub();
    Prv.AskBeforeSleep -> HalAskBeforeSleepPub;
}
