/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
