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

generic module PWMOnOffSwitchPub(uint8_t fillPercentage, uint16_t frequencyHz) {
    uses interface OutputPWM as PWM;
    provides interface OnOffSwitch as OnOff;
}
implementation{
    command error_t OnOff.on(){
        return call PWM.start(fillPercentage, frequencyHz);
    }

    command error_t OnOff.off(){
        return call PWM.stop();
    }
}
