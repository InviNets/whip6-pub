/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * Use this component to define a new ieee154 address that is known
 * to always have the radio on.
 */

generic configuration ThisIeee154ExtAddrAlwaysListensPub(
        uint8_t msb_0,
        uint8_t msb_1,
        uint8_t msb_2,
        uint8_t msb_3,
        uint8_t msb_4,
        uint8_t msb_5,
        uint8_t msb_6,
        uint8_t msb_7) {}
implementation
{
    components new ThisIeee154ExtAddrAlwaysListensPrv(
        msb_0,
        msb_1,
        msb_2,
        msb_3,
        msb_4,
        msb_5,
        msb_6,
        msb_7) as T;

    components Ieee154KnownPassiveListnersPub;
    Ieee154KnownPassiveListnersPub.PassiveListnersConnect -> T.Ieee154KnownPassiveListners;
}
