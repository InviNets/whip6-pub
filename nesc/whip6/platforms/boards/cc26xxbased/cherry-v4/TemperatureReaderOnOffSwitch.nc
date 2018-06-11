/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2018 Przemyslaw Gumienny
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

/**
 * @author Przemyslaw Gumienny
 */

generic module TemperatureReaderOnOffSwitch() {
    provides interface OnOffSwitch;
    provides interface Init @exactlyonce();
    uses interface IOPin as IOPin;
}

implementation {
    command error_t Init.init() {
        call IOPin.makeOutput();
        call IOPin.setLow();
        return SUCCESS;
    }

    command error_t OnOffSwitch.on() {
        call IOPin.setHigh();
        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        call IOPin.setLow();
        return SUCCESS;
    }
}
