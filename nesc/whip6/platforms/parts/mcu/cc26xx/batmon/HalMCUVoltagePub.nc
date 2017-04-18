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

#include "aon_batmon.h"
#include "DimensionTypes.h"

generic module HalMCUVoltagePub() {
    provides interface DimensionalRead<TMilliVolt, int16_t> as VDDDividedBy3;
}

implementation {
    bool reading = FALSE;

    task void read() {
        // See the CC13xx, CC26xx SimpleLink Wireless MCU Technical Reference
        // Manual, table 18-11.
        uint32_t raw = AONBatMonBatteryVoltageGet();

        int16_t value = (raw >> 8) * 1000 + (raw & 0xff) * 1000 / 0x100;
        value /= 3;
        reading = FALSE;
	    signal VDDDividedBy3.readDone(SUCCESS, value);
    }

    command error_t VDDDividedBy3.read() {
        if (reading) {
            return EBUSY;
        }
        post read();
        return SUCCESS;
    }

    default event void VDDDividedBy3.readDone(error_t status, int16_t value) {}
}
