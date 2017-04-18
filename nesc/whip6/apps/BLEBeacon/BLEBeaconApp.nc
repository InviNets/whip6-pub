/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration BLEBeaconApp {
}

implementation {
    components BoardStartupPub, BLEBeaconPrv as AppPrv;
    AppPrv.Boot -> BoardStartupPub;

    components new InviNetsBLEAdvertisersPub(APP_ADVERTISING_INTERVAL_MS);
    AppPrv.OnOffSwitch -> InviNetsBLEAdvertisersPub;
}
