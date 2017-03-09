/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
#include <stdio.h>

module SCIFUARTPrintfPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
} implementation {
    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(2048); // ms
    }

    event void Timer.fired() {
        int i;
        for (i = 0; i < 1000; i++)
            printf("Test printa troche dluzszego z liczbami %d %d\n", i, i);
        call Timer.startWithTimeoutFromNow(2048); // ms
    }
}
