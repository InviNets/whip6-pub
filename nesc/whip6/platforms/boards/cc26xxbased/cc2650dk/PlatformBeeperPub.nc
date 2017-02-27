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

configuration PlatformBeeperPub {
    provides interface Beeper;
}

implementation {
    components LedsPub as Leds;
    components new LedOnOffSwitchPub() as Switch;
    Switch.Led -> Leds.Led[3];
    components new OnOffBeeperPub(100, 20) as Impl;
    Impl.OnOffSwitch -> Switch;
    Beeper = Impl.Beeper;
}
