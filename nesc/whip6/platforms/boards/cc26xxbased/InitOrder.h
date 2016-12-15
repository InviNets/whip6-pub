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

#ifndef INIT_ORDER_H_
#define INIT_ORDER_H_

enum {
    // Keep this in sync with InitOrderPrv.nc
    INIT_PROCESSES = 100,
    INIT_POWER,
    INIT_PINS,
    INIT_RTC,
};

#endif
