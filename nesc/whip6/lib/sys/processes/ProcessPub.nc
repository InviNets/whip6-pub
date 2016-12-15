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


generic configuration ProcessPub(char name[], size_t stack_words,
        uint8_t prio) {
    provides interface Init;
    provides interface Process;
    provides interface Boot;
}
implementation
{
    components new BaseProcessPub(name, prio) as Impl;
    Init = Impl;
    Process = Impl;
    Boot = Impl;

    components new StackProviderPub(stack_words) as Stack;
    Impl.StackProvider -> Stack;

    components ProcessSchedulerPub;
    Impl.ProcessScheduler -> ProcessSchedulerPub;
}
