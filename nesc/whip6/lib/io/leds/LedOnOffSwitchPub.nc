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


generic module LedOnOffSwitchPub() {
    provides interface OnOffSwitch;
    uses interface Led;
}

implementation {
    command error_t OnOffSwitch.on() {
        call Led.on();
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        call Led.off();
        return SUCCESS;
    }
}
