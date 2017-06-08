/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 *
 * Configures a GPIO for a button/switch. Enables hysteresis and
 * pull-up/down. Configures interrupt edge.
 *
 * Actual presses should be handled by interrupts.
 */

#include "gpio.h"
#include "ioc.h"

generic module HalIOPinForButtonPub(bool activeHigh) {
    uses interface CC26xxPin @exactlyonce();
    uses interface GPIOEventConfig @exactlyonce();
    provides interface Button;
}

implementation {
    inline event void CC26xxPin.configure() {
        IOCPinTypeGpioInput(call CC26xxPin.IOId());
        IOCIOPortPullSet(call CC26xxPin.IOId(), activeHigh ? IOC_IOPULL_DOWN :
                IOC_IOPULL_UP);
        IOCIOHystSet(call CC26xxPin.IOId(), IOC_HYST_ENABLE);
        call GPIOEventConfig.triggerOnBothEdges();
        call GPIOEventConfig.setupExternalEvent();
    }

    inline command bool Button.isPressed() {
        if (activeHigh) {
            return GPIO_readDio(call CC26xxPin.IOId());
        } else {
            return !GPIO_readDio(call CC26xxPin.IOId());
        }
    }
}
