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
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 * 
 * Reads temperature every second and prints to the console.
 */

#include "stdio.h"

module TempReadPrv {
    uses interface Boot;
    uses interface Led;
    uses interface Timer<TMilli, uint32_t>;
    uses interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
}

implementation {
    event void Boot.booted() {
        call Led.off();
        call Timer.startWithTimeoutFromNow(1000);
    }

    event void Timer.fired() {
        error_t error;

        call Timer.startWithTimeoutFromLastTrigger(1000);
        call Led.on();
        error = call ReadTemp.read();
        if(error != SUCCESS) {
            printf("Error in call to read: %u.\n", error);
        }
    }

    event void ReadTemp.readDone(error_t result, int16_t val) {
        if(result != SUCCESS) {
            printf("Temperature read error: %u\n\r", result);
        } else {
            printf("Temperature in tenths of degree Celsius: %d\n\r", val);
        }
        call Led.off();
    }
}
