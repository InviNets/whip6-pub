/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic configuration LongButtonPressPub(uint16_t timeMs) {
    provides interface ButtonPress;
    uses interface ButtonPress as SubButtonPress;
}
implementation {
    components new LongButtonPressPrv(timeMs) as Prv;

    components new PlatformTimerMilliPub() as Timer;
    Prv.Timer -> Timer;

    ButtonPress = Prv.ButtonPress;
    SubButtonPress = Prv.SubButtonPress;
}
