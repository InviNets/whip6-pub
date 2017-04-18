/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Konrad Iwanicki
 * @author Michal Marschall <m.marschall@invinets.com>
 */

configuration RandomDemoApp {}

implementation {
    components PlatformRandomPub;
    components RandomDemoPrv as AppPrv;
    components BoardStartupPub;
    components new PlatformTimerMilliPub();
    AppPrv.Boot -> BoardStartupPub;
    AppPrv.Random -> PlatformRandomPub;
    AppPrv.Timer -> PlatformTimerMilliPub;
}
