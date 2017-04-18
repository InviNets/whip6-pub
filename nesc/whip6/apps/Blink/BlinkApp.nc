/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration BlinkApp {
}

implementation {
    components BoardStartupPub, BlinkPrv as AppPrv;
    AppPrv.Boot -> BoardStartupPub;

    components LedsPub;
    AppPrv.Led -> LedsPub.Led;

    components new PlatformTimerMilliPub();
    AppPrv.Timer -> PlatformTimerMilliPub;
}
