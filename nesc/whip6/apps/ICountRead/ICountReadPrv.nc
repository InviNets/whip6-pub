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

module ICountReadPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface EventCount<uint64_t> as ICount;
}

implementation {
    uint32_t timestamp;

    event void Boot.booted() {
        call ICount.start();
        timestamp = 0;
        call Timer.startWithTimeoutFromNow(INTERVAL_1S);
    }

    event void Timer.fired() {
        uint64_t ticks = 0;
        error_t res = SUCCESS;

        timestamp += 1;
        call Timer.startWithTimeoutFromLastTrigger(INTERVAL_1S);

        res = call ICount.read(&ticks);
        if (res != SUCCESS)
            printf("Failed to read ICount\n");
        else
            printf("ICount - number of ticks: %u, timestamp: %u\n",
                   (uint32_t)ticks, timestamp);
    }
}
