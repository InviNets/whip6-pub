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

configuration MainProcessPub {
    provides interface Init @exactlyonce();
    provides interface Process;
    provides interface McuSleep as SchedulerSleep @exactlyonce();
    provides interface Init as SchedulerTaskPostedHook @exactlyonce();
}
implementation
{
    components MainProcessPrv as Prv;
    Init = Prv.Init;
    Process = Prv.Process;
    SchedulerSleep = Prv.SchedulerSleep;
    SchedulerTaskPostedHook = Prv.SchedulerTaskPostedHook;

    components HalMainStackProviderPub as Stack;
    Prv.StackProvider -> Stack;

    components ProcessSchedulerPub;
    Prv.ProcessScheduler -> ProcessSchedulerPub;
}
