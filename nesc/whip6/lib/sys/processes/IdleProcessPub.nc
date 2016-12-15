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


#include "PlatformProcess.h"

configuration IdleProcessPub {
    provides interface Init @exactlyonce();
    uses interface McuSleep as IdleSleep @exactlyonce();
}
implementation
{
    components new ProcessPub("idle", 64, _PROCESS_PRIO_IDLE) as Process;
    Init = Process.Init;

    components IdleProcessPrv as Prv;
    Process.Boot <- Prv.Boot;
    IdleSleep = Prv.IdleSleep;

    components ProcessSchedulerPub;
    Prv.ProcessScheduler -> ProcessSchedulerPub;
}
