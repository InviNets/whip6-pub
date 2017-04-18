/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
