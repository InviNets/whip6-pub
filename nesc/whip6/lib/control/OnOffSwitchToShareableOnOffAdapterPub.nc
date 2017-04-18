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

generic module OnOffSwitchToShareableOnOffAdapterPub() {
    provides interface ShareableOnOff;

    uses interface OnOffSwitch @exactlyonce();
}

implementation {
    uint16_t timesOn = 0;

    command void ShareableOnOff.on() {
        if(timesOn++ == 0) {
            call OnOffSwitch.on();
        }
    }

    command void ShareableOnOff.off() {
        if(timesOn == 0) { /* prevent from underflow, which may cause improper behavior */
            return;
        }
        if(--timesOn == 0) {
            call OnOffSwitch.off();
        }
    }
}
