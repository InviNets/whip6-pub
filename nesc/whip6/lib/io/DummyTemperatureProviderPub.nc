/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */
 
#include "DimensionTypes.h"

generic module DummyTemperatureProviderPub() {
    provides interface DimensionalRead<TDeciCelsius, int16_t> as Temperature;
}

implementation {
    command error_t Temperature.read() {
        return FAIL;
    }

    default event void Temperature.readDone(error_t result, int16_t val) {}
}
