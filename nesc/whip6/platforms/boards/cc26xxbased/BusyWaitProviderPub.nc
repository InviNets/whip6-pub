/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 */

#include "TimerTypes.h"

configuration BusyWaitProviderPub {
    provides interface BusyWait<TMicro, uint16_t>;
}
implementation {
    components HalBusyWaitPub;
    BusyWait = HalBusyWaitPub;
}
