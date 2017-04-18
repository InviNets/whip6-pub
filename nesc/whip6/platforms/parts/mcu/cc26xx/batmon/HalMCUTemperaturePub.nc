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

generic module HalMCUTemperaturePub() {
    provides interface DimensionalRead<TDeciCelsius, int16_t>;
}

implementation {
    bool reading = FALSE;

    task void read() {
        int16_t value = AONBatMonTemperatureGetDegC();
        value *= 10;
        reading = FALSE;
	    signal DimensionalRead.readDone(SUCCESS, value);
    }

    command error_t DimensionalRead.read() {
        if (reading) {
            return EBUSY;
        }
        post read();
        return SUCCESS;
    }

    default event void DimensionalRead.readDone(error_t status, int16_t value) {}
}
