/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * Provides an array of Led interface that may or may not
 * be backed by real leds.
 */

generic module VirtualLedsPub() {
    provides interface Led as VirtualLeds[uint8_t ledNr];

    uses interface Led as RealLeds[uint8_t ledNr];
}
implementation {
    command bool VirtualLeds.isOn[uint8_t ledNr](){
        return call RealLeds.isOn[ledNr]();
    }

    command void VirtualLeds.set[uint8_t ledNr](bool on){
        call RealLeds.set[ledNr](on);
    }

    command void VirtualLeds.toggle[uint8_t ledNr](){
        call RealLeds.toggle[ledNr]();
    }

    command void VirtualLeds.off[uint8_t ledNr](){
        call RealLeds.off[ledNr]();
    }

    command void VirtualLeds.on[uint8_t ledNr](){
        call RealLeds.on[ledNr]();
    }

    default command bool RealLeds.isOn[uint8_t ledNr]() { return FALSE; }
    default command void RealLeds.set[uint8_t ledNr](bool on) {}
    default command void RealLeds.toggle[uint8_t ledNr]() {}
    default command void RealLeds.off[uint8_t ledNr]() {}
    default command void RealLeds.on[uint8_t ledNr]() {}
}
