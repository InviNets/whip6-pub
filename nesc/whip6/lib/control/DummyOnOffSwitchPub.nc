/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
