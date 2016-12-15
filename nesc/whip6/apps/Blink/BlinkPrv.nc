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


module BlinkPrv {
    uses interface Boot;
    uses interface Led[uint8_t ledNr];
    uses interface Timer<TMilli, uint32_t>;
}

implementation {
    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(1024);
    }

    event void Timer.fired() {
        uint16_t i;
        for(i = 0; i < 256; i++)
            call Led.toggle[i]();
        call Timer.startWithTimeoutFromLastTrigger(1024);
    }
}
