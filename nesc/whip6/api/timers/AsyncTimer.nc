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

interface AsyncTimer<precision_tag, time_type_t>
{
    async command void startWithTimeoutFromTime(time_type_t t0, time_type_t dt);
    async command void stop();
    async command bool isRunning();
    async command time_type_t getNow();
    async event void fired();
}
