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

generic module DummyIOPinPub(bool isOutput, bool initialValue) {
    provides interface IOPin;
}

implementation {
    bool value = initialValue;

    command bool IOPin.get() {
        return value;
    }

    command void IOPin.setHigh() {
        if (isOutput) {
            value = TRUE;
        }
    }

    command void IOPin.setLow() {
        if (isOutput) {
            value = FALSE;
        }
    }

    command void IOPin.toggle() {
        if (isOutput) {
            value = !value;
        }
    }

    command bool IOPin.isOutput() {
        return isOutput;
    }

    command bool IOPin.isInput() {
        return !isOutput;
    }

	command void IOPin.makeOutput(){
    }

    command void IOPin.makeInput() {
    }
}
