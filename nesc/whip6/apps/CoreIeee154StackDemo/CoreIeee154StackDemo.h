/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_CORE_IEEE154_STACK_DEMO_APP_H__
#define __WHIP6_CORE_IEEE154_STACK_DEMO_APP_H__

#include <stdio.h>
#include "Ieee154.h"


enum
{
    BEACON_TIMER_PERIOD_IN_MILLIS = 1024UL * 8UL,
    TARGET_TIMER_DELAY_IN_MILLIS = 1024UL,
    STATS_TIMER_PERIOD_IN_MILLIS = 1024UL * 15UL,
    SOFTWARE_ACK_DELAY_IN_MILLIS = 512UL,
};

#define DEMO_STAT_INDEXING_STR "CoreIeee154StackDemoApp::MyStat"

#endif /* __WHIP6_CORE_IEEE154_STACK_DEMO_APP_H__ */
