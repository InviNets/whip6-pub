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

    uses interface StatsIncrementer<uint32_t> as NumConnectionEvents;
    uses interface StatsIncrementer<uint32_t> as NumConnectionPacketsSent;
}
implementation {
    components HalMyNewtBLEPhyPrv as Prv;
    Init = Prv.Init;
    NumConnectionPacketsSent = Prv.NumConnectionPacketsSent;
    NumConnectionEvents = Prv.NumConnectionEvents;

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
