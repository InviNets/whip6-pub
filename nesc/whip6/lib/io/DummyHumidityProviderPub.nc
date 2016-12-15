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
 * @author Michal Marschall <m.marschall@invinets.com>
 */
 
#include "DimensionTypes.h"

generic module DummyHumidityProviderPub() {
    provides interface DimensionalRead<TPercentage, uint8_t> as Humidity;
}

implementation {
    command error_t Humidity.read() {
        return FAIL;
    }

    default event void Humidity.readDone(error_t result, uint8_t val) {}
}
