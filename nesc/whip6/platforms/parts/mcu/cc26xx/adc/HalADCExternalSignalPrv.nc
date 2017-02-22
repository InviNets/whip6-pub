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
 * Exposes interfaces for reading the ADC in a single-read mode.
 *
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */

#include <driverlib/aux_adc.h>
#include "DimensionTypes.h"

generic module HalADCExternalSignalPrv() {
    provides interface DimensionalRead<TMilliVolt, int16_t> as Read;
    uses interface DimensionalRead<TMilliVolt, int16_t> as SubRead[uint8_t port];
    uses interface CC26xxAUXPin as AUXPin;
}
implementation {
    command error_t Read.read() {        
        uint8_t num = call AUXPin.AUXIOId();
        if (num >= 8) {
            panic("AUXIO>=8 is not analog");
        }
        return call SubRead.read[ADC_COMPB_IN_AUXIO0 - num]();
    }

    event void SubRead.readDone[uint8_t port](error_t status, int16_t value) {
        signal Read.readDone(status, value);
    }

    default event void Read.readDone(error_t status, int16_t value) {}
}
