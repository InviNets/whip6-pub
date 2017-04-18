/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Konrad Iwanicki
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include <stdio.h>

module RandomDemoPrv {
    uses interface Boot;
    uses interface Random;
    uses interface Timer<TMilli, uint32_t>;
}

implementation {
    enum {
        NUM_RANDOM_NUMBERS_TO_PRINT = 10,
        PRINT_PERIOD_MS = 1024,
    };

    event void Timer.fired() {
        uint32_t r;
        uint16_t i;

        for(i = NUM_RANDOM_NUMBERS_TO_PRINT; i > 0; --i) {
            r = call Random.rand32();
            printf("%lu ", r);
        }
        printf("\r\n");

        call Timer.startWithTimeoutFromLastTrigger(PRINT_PERIOD_MS);
    }

    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(PRINT_PERIOD_MS);
    }
}
