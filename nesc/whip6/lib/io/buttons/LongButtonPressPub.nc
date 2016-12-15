/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
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
