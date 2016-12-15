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


#include "TimerTypes.h"

interface Timer<precision_tag, time_type_t>
{
    command void startWithTimeoutFromNow(time_type_t dt);
    command void startWithTimeoutFromLastTrigger(time_type_t dt);
    command void startWithTimeoutFromTime(time_type_t t0, time_type_t dt);
    command void stop();
    command bool isRunning();
    command time_type_t getLastTrigger();
    command time_type_t getNow();
    command time_type_t getStartTime();
    command time_type_t getTimeoutFromStartTime();
    event void fired();
}
