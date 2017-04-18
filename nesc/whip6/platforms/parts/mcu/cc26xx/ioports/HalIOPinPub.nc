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

#include "gpio.h"
#include "ioc.h"
#include "CC26xxPinConfig.h"

generic module HalIOPinPub(cc26xx_pin_config_t defaultConfig) {
    provides interface IOPin;
    provides interface IOPinPull;
    uses interface CC26xxPin @exactlyonce();
}

implementation {
    inline event void CC26xxPin.configure() {
        switch (defaultConfig) {
            case INPUT_FLOATING:
                call IOPin.makeInput();
                call IOPinPull.noPull();
                break;
            case INPUT_PULL_UP:
                call IOPin.makeInput();
                call IOPinPull.pullUp();
                break;
            case INPUT_PULL_DOWN:
                call IOPin.makeInput();
                call IOPinPull.pullDown();
                break;
            case OUTPUT_HIGH:
                call IOPin.makeOutput();
                call IOPin.setHigh();
                break;
            case OUTPUT_LOW:
                call IOPin.makeOutput();
                call IOPin.setLow();
        }
    }

    command bool IOPin.get() {
        return GPIO_readDio(call CC26xxPin.IOId());
    }

    command void IOPin.setHigh() {
        GPIO_setDio(call CC26xxPin.IOId());
    }

    command void IOPin.setLow() {
        GPIO_clearDio(call CC26xxPin.IOId());
    }

    command void IOPin.toggle() {
        GPIO_toggleDio(call CC26xxPin.IOId());
    }

    command bool IOPin.isOutput() {
        return GPIO_getOutputEnableDio(call CC26xxPin.IOId()) ==
            GPIO_OUTPUT_ENABLE;
    }

    command bool IOPin.isInput() {
        return GPIO_getOutputEnableDio(call CC26xxPin.IOId()) ==
            GPIO_OUTPUT_DISABLE;
    }

	command void IOPin.makeOutput(){
        IOCPinTypeGpioOutput(call CC26xxPin.IOId());
    }

    command void IOPin.makeInput() {
        IOCPinTypeGpioInput(call CC26xxPin.IOId());
    }

    command void IOPinPull.pullUp() {
        IOCIOPortPullSet(call CC26xxPin.IOId(), IOC_IOPULL_UP);
    }

    command void IOPinPull.pullDown() {
        IOCIOPortPullSet(call CC26xxPin.IOId(), IOC_IOPULL_DOWN);
    }

    command void IOPinPull.noPull() {
        IOCIOPortPullSet(call CC26xxPin.IOId(), IOC_NO_IOPULL);
    }
}
