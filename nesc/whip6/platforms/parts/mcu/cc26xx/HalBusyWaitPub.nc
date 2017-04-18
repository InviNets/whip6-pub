/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

#include "cpu.h"
#include "TimerTypes.h"

module HalBusyWaitPub {
    provides interface BusyWait<TMicro, uint16_t>;
}
implementation {
    async command void BusyWait.wait(uint16_t dt) {
        // We run off 48MHz clock and each loop of CPUdelay
        // takes 3 clock cycles, as documented.
        if (dt) {
            CPUdelay(((uint32_t)dt)*48/3);
        }
        // TODO(accek): this does not account interrupts and should probably be
        // re-implemented using the SysTick timer
    }
}
