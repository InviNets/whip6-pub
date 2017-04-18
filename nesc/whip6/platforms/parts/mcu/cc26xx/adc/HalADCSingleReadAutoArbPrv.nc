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
 * Allows for reading ADC values without a need to call Resource.request().
 *
 * @author Michal Marschall <m.marschall@invinets.com>
 */
 
#include "DimensionTypes.h"

generic module HalADCSingleReadAutoArbPrv() {
    provides interface DimensionalRead<TMilliVolt, int16_t> as ReadSource[uint8_t port];

    uses interface ArbiterInfo;
    uses interface Resource;
    uses interface DimensionalRead<TMilliVolt, int16_t> as SubRead[uint8_t userId, uint8_t port];
}

implementation {
    uint8_t requestedPort;
    bool havingResource = FALSE;

    command error_t ReadSource.read[uint8_t port]() {
        error_t error;

        error = call Resource.request();
        if(error == SUCCESS) {
            requestedPort = port;
        }
        return error;
    }

    event void Resource.granted() {
        error_t error;

        havingResource = TRUE;
        error = call SubRead.read[call ArbiterInfo.userId(), requestedPort]();
        if(error != SUCCESS) {
            call Resource.release();
            signal ReadSource.readDone[requestedPort](error, 0);
        }
    }

    event void SubRead.readDone[uint8_t userId, uint8_t port](error_t result, int16_t value) {
        if(havingResource && port == requestedPort) {
            havingResource = FALSE;
            call Resource.release();
            signal ReadSource.readDone[port](result, value);
        }
    }

    default event void ReadSource.readDone[uint8_t port](error_t result, int16_t value) {}
}
