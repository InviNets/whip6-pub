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
#include "PlatformProcess.h"

module MainProcessPrv {
    provides interface Init;
    provides interface Process;
    provides interface McuSleep as SchedulerSleep;
    provides interface Init as SchedulerTaskPostedHook;
    uses interface ProcessScheduler;
    uses interface StackProvider;
}
implementation
{
    process_t process;

    inline async command process_t* Process.get() {
        return &process;
    }

    inline command void SchedulerSleep.sleep() {
        call ProcessScheduler.suspend(&process);
        call ProcessScheduler.schedule();
    }

    inline command error_t SchedulerTaskPostedHook.init() {
        call ProcessScheduler.resume(&process);
        return SUCCESS;
    }

    command error_t Init.init() {
        call ProcessScheduler.initProcess(&process, "main", NULL, NULL,
                PROCESS_PRIO_DEFAULT, call StackProvider.getBottomOfStack(),
                call StackProvider.getStackSizeInWords());
        call ProcessScheduler.addProcess(&process);
        call ProcessScheduler.setMainProcess(&process);
        return SUCCESS;
    }
}

