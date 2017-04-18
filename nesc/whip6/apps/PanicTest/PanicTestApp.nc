/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


configuration PanicTestApp {
}
implementation {
    components BoardStartupPub;
    components PanicTestPrv as AppPrv;
    components new PlatformTimerMilliPub() as TimerPrv;

    AppPrv.Boot -> BoardStartupPub;
    AppPrv.Timer -> TimerPrv;

    components PersistentErrorLogDumperPub;
}
