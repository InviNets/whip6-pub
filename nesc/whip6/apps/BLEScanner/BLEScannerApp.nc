/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration BLEScannerApp {
}

implementation {
    components BoardStartupPub, BLEScannerPrv as AppPrv;
    AppPrv.Boot -> BoardStartupPub;

    components PlatformBLEScannerPub;
    AppPrv.RawBLEScanner -> PlatformBLEScannerPub;

    components new PlatformTimerMilliPub() as InitTimerPrv;
    AppPrv.InitTimer -> InitTimerPrv;
}
