/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

configuration HalPowerInitPub {
    provides interface Init;
}
implementation {
    components HalPowerInitPrv as Impl;
    Init = Impl;

    components CC26xxPowerDomainsPub as PowerDomains;
    Impl.PeriphDomain -> PowerDomains.PeriphDomain;

    components HalCC26xxSleepPub;
    Impl.AskBeforeSleep -> HalCC26xxSleepPub.AskBeforeSleep;

    components new PlatformTimerMilliPub() as Timer;
    Impl.Timer -> Timer;
}
