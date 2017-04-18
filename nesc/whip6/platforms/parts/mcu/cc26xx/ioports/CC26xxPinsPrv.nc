/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

#include "ioc.h"

module CC26xxPinsPrv {
    provides interface CC26xxPin as DIO[uint32_t IOId];
    provides interface Init @exactlyonce();
    uses interface CC26xxPinsDefaultConfig as DefaultConfig @atmostonce();
}
implementation {
    inline async command uint32_t DIO.IOId[uint32_t IOId]() {
        ASSERT(IOId < NUM_IO_MAX);
        return IOId;
    }

    inline default event void DIO.configure[uint32_t IOId]() {
        call DefaultConfig.configure(IOId);
    }

    inline default command void DefaultConfig.configure(uint32_t IOId) {
        // By default, do nothing. The default configuration leaves
        // the drivers disconnected, with no leakage even if the signal is
        // floating.
        //
        // Note that this need not be appropriate if some external devices
        // are actually connected, as they may have some leakage in case
        // of floating inputs.
        //
        // From the Reference Manual:
        //
        // "By default, the I/O driver (output) and input buffer (input) are
        //  disabled at power on or reset, and thus the I/O pin can safely be
        //  left unconnected (floating).
        //
        //  If the I/O pin is tri-stated and connected to a node with a different
        //  voltage potential; there might be a small leakage current going
        //  through the pin. The same applies to an I/O pin configured as input,
        //  where the pin is connected to a voltage source (for example VDD / 2).
        //  The input is then an undefined value of either 0 or 1."
    }

    inline command error_t Init.init() {
        uint32_t i;
        for (i = 0; i < NUM_IO_MAX; i++) {
            signal DIO.configure[i]();
        }
        return SUCCESS;
    }
}
