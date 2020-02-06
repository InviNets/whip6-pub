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

#if ((! defined(CC26XX_VIMS_GPRAM_MODE)) || ((CC26XX_VIMS_GPRAM_MODE) != 1))
#define CC26XX_PLACE_IN_GPRAM __attribute__((deprecated("Cannot place objects in CC26XX GPRAM without CC26XX_VIMS_GPRAM_MODE defined and set to 1")))
#else
#define CC26XX_PLACE_IN_GPRAM __attribute__((section(".gpram")))
#endif

#ifndef CC26XX_VIMS_GPRAM_MODE
#define CC26XX_VIMS_GPRAM_MODE false
#endif

extern uint8_t _lgpram;
extern uint8_t _gpram;
extern uint8_t _egpram;

module CC26xxVIMSPrv {
    provides interface Bootstrap;
}
implementation {
    command inline void Bootstrap.bootstrap() {
        if (CC26XX_VIMS_GPRAM_MODE) {
            /* Switch VIMS to GPRAM mode with waiting until mode actually switches */
            VIMSModeSafeSet(VIMS_BASE, VIMS_MODE_DISABLED, true);

            memcpy(&_gpram, &_lgpram, &_egpram - &_gpram);
        }
    }
}

