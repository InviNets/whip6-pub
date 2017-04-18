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

interface AsyncCounter<precision_tag, time_type_t>
{
    async command time_type_t getNow();
}
