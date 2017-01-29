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

/**
 * @author Szymon Acedanski
 */

module HalPanicHookPub {
    provides interface PanicHook @exactlyonce();
}
implementation {
    /* May be overriden in MCU-specific code. */
    __attribute__((weak))
    void mcu_panic_hook(uint16_t panic_id) @spontaneous() @C() {
        // do nothing
    }

    command void PanicHook.willPanic(uint16_t panicId) {
        mcu_panic_hook(panicId);
    }
}
