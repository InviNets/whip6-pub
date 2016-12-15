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

module VoltageReadPrv {
    uses interface Boot;
    uses interface Led;
    uses interface Timer<TMilli, uint32_t>;
    uses interface DimensionalRead<TMilliVolt, int16_t> as ReadVoltage;
}

implementation {
    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(1000);
    }
    
    event void Timer.fired() {
        error_t error;

        call Timer.startWithTimeoutFromLastTrigger(1000);
        call Led.toggle();
        error = call ReadVoltage.read();
        if(error != SUCCESS) {
            printf("Error in call to read: %u.\n", error);
        }
    }

    event void ReadVoltage.readDone(error_t result, int16_t val) {
        if(result != SUCCESS) {
            printf("Error during read: %u.\n", result);
        }
        printf("VDD voltage is %d mV.\n\n", val * 3);
    }
}
