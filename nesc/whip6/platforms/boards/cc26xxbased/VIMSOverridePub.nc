/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 *
 */


#include <driverlib/vims.h>

#define CC26XX_PLACE_IN_GPRAM __attribute__((section(".gpram")))

#ifndef CC26XX_VIMS_GPRAM_MODE
#define CC26XX_VIMS_GPRAM_MODE false
#endif

extern uint8_t _lgpram;
extern uint8_t _gpram;
extern uint8_t _egpram;

module VIMSOverridePub {}
implementation {
    void trimVIMSMode() @C() {
        if (CC26XX_VIMS_GPRAM_MODE) {
            /* Switch VIMS to GPRAM mode with waiting until mode actually switches */
            VIMSModeSafeSet(VIMS_BASE, VIMS_MODE_DISABLED, true);

            memcpy(&_gpram, &_lgpram, &_egpram - &_gpram);
        }
    }
}

