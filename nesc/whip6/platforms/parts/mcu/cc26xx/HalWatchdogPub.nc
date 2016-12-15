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


#include "watchdog.h"

module HalWatchdogPub
{
    provides interface Watchdog;
}
implementation {
    uint32_t timeout_clocks;

    command void Watchdog.dieIfUnclearedFor(uint32_t miliseconds) {

        // TODO(accek): make it NMI and implement a handler

        // TODO(accek): this stupid watchdog slow down in sleep...

#warning FIXME: Watchdog does not count in sleep.

        // The watchdog normally runs on the system clock / 32, i.e.
        // 48MHz/32.
        timeout_clocks = miliseconds * 1500;

        WatchdogUnlock();
        WatchdogReloadSet(timeout_clocks);
        WatchdogResetEnable();
        WatchdogStallEnable();  // Do not count when a debugger stops execution
        WatchdogEnable();
        WatchdogLock();
    }

    command uint32_t Watchdog.getActualInterval() {
        return timeout_clocks / 1500;
    }

    command void Watchdog.postponeDeath() {
        WatchdogUnlock();
        WatchdogReloadSet(timeout_clocks);
        WatchdogLock();
    }
}

