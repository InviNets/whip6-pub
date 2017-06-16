/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
generic configuration ICountPub() {
    provides interface EventCount;
}

implementation {
    components new HalEventCountPub() as EvCnt;
    EventCount = EvCnt.EvCntA;

    components CC26xxPinsPub as Pins;
    EvCnt.PinA -> Pins.DIO23;
}
