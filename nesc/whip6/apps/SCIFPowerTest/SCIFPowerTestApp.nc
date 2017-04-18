/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration SCIFPowerTestApp {
}

implementation {
    components BoardStartupPub, SCIFPowerTestPrv;
    SCIFPowerTestPrv.Boot -> BoardStartupPub;

    components new PlatformTimerMilliPub();
    SCIFPowerTestPrv.Timer -> PlatformTimerMilliPub;

    components PlatformSCIFPwrtestPub as SCIF;
    SCIFPowerTestPrv.SCOnOff -> SCIF;

    components HalCC26xxSleepPub as Sleep;
    components LedsPub;
    Sleep.NoDeepSleepLed -> LedsPub.Red;
    Sleep.NoIdleSleepLed -> LedsPub.Green;
}
