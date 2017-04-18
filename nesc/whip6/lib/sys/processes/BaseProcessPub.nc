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

generic module BaseProcessPub(char name[], uint8_t prio) {
    provides interface Init;
    provides interface Process;
    provides interface Boot;
    uses interface ProcessScheduler;
    uses interface StackProvider;
}
implementation
{
    process_t process;

    inline async command process_t* Process.get() {
        return &process;
    }

    void process_body(void* arg) {
        signal Boot.booted();
        panic("Process exited, this should never happen.");
    }

    command error_t Init.init() {
        call ProcessScheduler.initProcess(&process, name, process_body, NULL,
                prio, call StackProvider.getBottomOfStack(),
                call StackProvider.getStackSizeInWords());
        call ProcessScheduler.addProcess(&process);
        return SUCCESS;
    }
}
