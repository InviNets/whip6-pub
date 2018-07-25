/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#define INTERVAL_1S 1024

module ThermPowerUsePrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface EventCount<uint64_t> as ICount;
    uses interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
}

implementation {
    enum {
        INIT,
        IDLING,
        READING_TEMP,
        LAST_READ,
    };

    int state = INIT;

    void startReadLoop();
    void readTemperature();
    void endTempReadLoop();

    event void Boot.booted() {
        printf("Node boot complete\n");
        call ICount.start();
        state = IDLING;
        startReadLoop();
    }

    void startReadLoop() {
        error_t res = SUCCESS;
        uint64_t ticks = 0;
        uint32_t timestamp = call Timer.getNow();

        res = call ICount.read(&ticks);
        if (res != SUCCESS)
            printf("Failed to read ICount\n");
        else {
            printf("Finished cycle with disabled thermometer: icount: %u, timestamp: %u\n", (uint32_t)ticks, timestamp);
        }

        call Timer.startWithTimeoutFromNow(INTERVAL_1S);
        readTemperature();
    }

    void readTemperature() {
        error_t error;

        error = call ReadTemp.read();
        if(error != SUCCESS) {
            printf("Error in call to read: %u\n\r", error);
        }

        state = READING_TEMP;
    }

    event void ReadTemp.readDone(error_t result, int16_t val) {
        if(result != SUCCESS) {
            printf("Temperature read error: %u\n\r", result);
        } else {
            printf("Temperature in tenths of degree Celsius: %d\n\r", val);
        }

        if (state == READING_TEMP)
            readTemperature();
        else if(state == LAST_READ)
            endTempReadLoop();
    }

    void endTempReadLoop() {
        error_t res = SUCCESS;
        uint64_t ticks = 0;


        res = call ICount.read(&ticks);
        if (res != SUCCESS)
            printf("Failed to read ICount\n");
        else {
            uint32_t timestamp = call Timer.getNow();
            printf("Finished cycle with continous thermometer reads: icount: %u, timestamp: %u\n", (uint32_t)ticks, timestamp);
        }

        call Timer.startWithTimeoutFromNow(INTERVAL_1S);
        state = IDLING;
    }

    event void Timer.fired() {
        if (state == IDLING)
            startReadLoop();
        else if(state == READING_TEMP)
            state = LAST_READ;
    }
}
