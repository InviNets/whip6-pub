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


generic module CC26xxTimerPrv(uint32_t base, int number) {
    provides interface CC26xxTimer @atmostonce();
}

implementation {
    async command uint32_t CC26xxTimer.base() {
        return base;
    }
    async command int CC26xxTimer.number() {
        return number;
    }
}
