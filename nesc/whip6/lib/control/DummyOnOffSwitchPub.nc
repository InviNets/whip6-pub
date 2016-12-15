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
 * @author Szymon Acedanski
 */

generic module DummyOnOffSwitchPub() {
    provides interface OnOffSwitch;
}

implementation {
    command error_t OnOffSwitch.on() {
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        return SUCCESS;
    }
}
