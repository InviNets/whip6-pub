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

configuration Eui64DemoApp {}

implementation {
    components LocalIeeeEui64ProviderPub;
    components Eui64DemoAppPrv as AppPrv;
    components BoardStartupPub;
    components new PlatformTimerMilliPub();

    AppPrv.Boot -> BoardStartupPub;
    AppPrv.Eui64Provider -> LocalIeeeEui64ProviderPub;
    AppPrv.Timer -> PlatformTimerMilliPub;
}
