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
 * Implements the interface to read ADC channels in single read mode.
 *
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */

#include "aux_adc.h"
#include "Assert.h"
#include "DimensionTypes.h"

module HalADCSingleReadPrv {
    provides interface DimensionalRead<TMilliVolt, int16_t> as ReadSource[uint8_t userId, uint8_t port];

    uses {
        interface ArbiterInfo;
    }
}

implementation {
    enum {
        IDLE                = 128, // Must be greater than 2^4.
    };

    uint8_t readingPortNr = IDLE;

    task void readOnPort() {
        uint8_t userId = call ArbiterInfo.userId();
        uint8_t port = readingPortNr;
        int16_t value = 0;
        uint32_t raw;
        int32_t adjusted;
        readingPortNr = IDLE;

        // TODO(accek): assert that AUX domain is powered and clocked

        // TODO(accek): and even if it is, I'm pretty sure the ADC clock must be
        // switched on separately.

        AUXADCEnableSync(AUXADC_REF_FIXED, AUXADC_SAMPLE_TIME_170_US,
                AUXADC_TRIGGER_MANUAL);
        AUXADCSelectInput(port);
        AUXADCGenManualTrigger();
        raw = AUXADCReadFifo();
        adjusted = AUXADCAdjustValueForGainAndOffset(raw,
                AUXADCGetAdjustmentGain(AUXADC_REF_FIXED),
                AUXADCGetAdjustmentOffset(AUXADC_REF_FIXED));
        value = AUXADCValueToMicrovolts(
                    AUXADC_FIXED_REF_VOLTAGE_NORMAL, adjusted) / 1000;
	     signal ReadSource.readDone[userId, port](SUCCESS, value);
    }

    command error_t ReadSource.read[uint8_t userId, uint8_t port]() {        
        if(userId != call ArbiterInfo.userId()) {
            return EBUSY;
        }
        if(readingPortNr != IDLE) {
            return EBUSY;
        }

        readingPortNr = port;
        post readOnPort();
        return SUCCESS;
    }

    default event void ReadSource.readDone[uint8_t userId, uint8_t port](error_t status, int16_t value) {}
}
