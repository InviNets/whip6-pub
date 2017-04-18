/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "PlatformProcess.h"

module IdleProcessPrv {
    uses interface Boot;
    uses interface McuSleep as IdleSleep @exactlyonce();
    uses interface ProcessScheduler;
}
implementation
{
    event void Boot.booted() {
        for (;;) {
            call ProcessScheduler.schedule();
            atomic {
                if (!call ProcessScheduler.isContextSwitchPending()) {
                    call IdleSleep.sleep();
                }
            }
        }
    }
}
