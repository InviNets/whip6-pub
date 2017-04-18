/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * Defines the global initialization order. See comment at BoardStartupPub.
 * 
 * Keep this in sync with InitOrder.h
 */

#include "InitOrder.h"

module InitOrderPrv {
    provides interface Init as SystemInitEntry;

    uses interface Init as InitSequence[uint8_t level];
}
implementation{
    command error_t SystemInitEntry.init(){
        error_t result = SUCCESS;
        uint8_t init_level;

#define RUN(LVL) result = ecombine(result, call InitSequence.init[(uint8_t)LVL]())

        // Note that posting NesC tasks before initializing processes
        // will hardfault.
        RUN(INIT_PROCESSES);

        RUN(INIT_POWER);
        RUN(INIT_PINS);
        RUN(INIT_RTC);

        for (init_level = 0; init_level < 16; init_level++)
            RUN(init_level);

        return result;
    }

    default command error_t InitSequence.init[uint8_t level]() { return SUCCESS; }
}
