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


#include <stdio.h>

module PanicTestPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t> as Timer;
    uses interface PersistentErrorLog as ErrorLog;
}
implementation {
    event void Boot.booted() {
        printf("[PanicTestPrv] Booting.\n");
        call Timer.startWithTimeoutFromNow(15000);
    }

    event void Timer.fired() {
        printf("[PanicTestPrv] Generating panic...\n");
        _panic(4242);
    }
}

