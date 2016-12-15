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
