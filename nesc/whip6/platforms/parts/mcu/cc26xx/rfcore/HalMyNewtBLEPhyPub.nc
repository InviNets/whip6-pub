/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration HalMyNewtBLEPhyPub {
    provides interface Init @exactlyonce();
}
implementation {
    components HalMyNewtBLEPhyPrv as Prv;
    Init = Prv.Init;

    components RFCorePrv;
    Prv.RFCore -> RFCorePrv;

    components RFCoreRadioPrv;
    Prv.RFCoreClaim -> RFCoreRadioPrv.ClaimBLE;
    Init = RFCoreRadioPrv.Init;

    components new PlatformTimerMilliPub() as WatchdogTimer;
    Prv.WatchdogTimer -> WatchdogTimer;

    components HalRadioPub;

    components MyNewtOSGluePrv;
    Prv.MyNewtCPUTime -> MyNewtOSGluePrv.MyNewtCPUTime;
}
