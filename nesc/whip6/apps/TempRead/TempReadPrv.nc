/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

/**
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Reads temperature every second and prints to the console.
 */

#include "stdio.h"

module TempReadPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
}

implementation {
    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(1000);
    }

    event void Timer.fired() {
        error_t error;

        call Timer.startWithTimeoutFromLastTrigger(2000);
        error = call ReadTemp.read();
        if(error != SUCCESS) {
            printf("Error in call to read: %u\n\r", error);
        }
    }

    event void ReadTemp.readDone(error_t result, int16_t val) {
        if(result != SUCCESS) {
            printf("Temperature read error: %u\n\r", result);
        } else {
            printf("Temperature in tenths of degree Celsius: %d\n\r", val);
        }
    }
}
