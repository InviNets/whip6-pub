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

generic module ShareableOnOffToOnOffSwitchAdapterPub() {
    provides interface OnOffSwitch;

    uses interface ShareableOnOff;
}

implementation {
    command error_t OnOffSwitch.on() {
        call ShareableOnOff.on();
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        call ShareableOnOff.off();
        return SUCCESS;
    }

    default command void ShareableOnOff.on() { }

    default command void ShareableOnOff.off() { }
}
