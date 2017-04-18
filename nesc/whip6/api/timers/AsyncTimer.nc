/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
