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

/**
 * @author Przemyslaw Horban <extremegf@gmail.com>
 */

#include "TimerTypes.h"

configuration BusyWaitProviderPub {
    provides interface BusyWait<TMicro, uint16_t>;
}
implementation {
    components HalBusyWaitPub;
    BusyWait = HalBusyWaitPub;
}
