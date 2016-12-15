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

/**
 * Use this component to define a new ieee154 address that is known
 * to always have the radio on.
 */

generic configuration ThisIeee154ShortAddrAlwaysListensPub(uint16_t shortAddr) {}
implementation
{
    components new ThisIeee154ShortAddrAlwaysListensPrv(shortAddr) as T;

    components Ieee154KnownPassiveListnersPub;
    Ieee154KnownPassiveListnersPub.PassiveListnersConnect -> T.Ieee154KnownPassiveListners;
}

