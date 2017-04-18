/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

generic configuration OnOffBeeperPub(uint32_t beepTimeMs,
        uint32_t shortestBeepTimeMs) {
    provides interface Beeper;
    uses interface OnOffSwitch;
}
implementation {
    components new OnOffBeeperPrv(beepTimeMs, shortestBeepTimeMs) as Prv;

    components new PlatformTimerMilliPub() as Timer;
    Prv.Timer -> Timer;

    OnOffSwitch = Prv.OnOffSwitch;
    Beeper = Prv.Beeper;
}
