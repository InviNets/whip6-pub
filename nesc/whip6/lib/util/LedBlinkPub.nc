/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

generic configuration LedBlinkPub() {
    uses interface Led;

    provides interface LedBlink;
}

implementation {
    components new LedBlinkPrv();
    components new PlatformTimerMilliPub() as Timer;
    LedBlinkPrv.Timer -> Timer;

    Led = LedBlinkPrv;
    LedBlink = LedBlinkPrv;
}
