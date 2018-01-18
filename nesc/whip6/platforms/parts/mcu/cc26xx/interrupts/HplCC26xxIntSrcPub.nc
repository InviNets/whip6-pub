/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 * 
 * CC26xx interrupt sources.
 */

#include "hw_ints.h"
#include "interrupt.h"
#include "GlobalPanic.h"

static void spurious_interrupt(uint8_t num) {
    IntDisable(num);
    panic("Spurious interrupt");
}

module HplCC26xxIntSrcPub {
    #define INT(N, IFACE) provides interface InterruptSource as IFACE @atmostonce();
    #include "CC26xxIntSources.h"
    #undef INT
}
implementation {
    #define INT(N, IFACE) \
        /* Do not inline to have the caller easily visible under GDB. */ \
        void __attribute__((noinline)) IFACE##Handler() @hwevent() @C() { \
            signal IFACE.interruptFired(); \
        } \
        inline async command void IFACE.enable() { IntEnable(N); } \
        inline async command void IFACE.disable() { IntDisable(N); } \
        inline async command void IFACE.clearPending() { IntPendClear(N); } \
        inline async command bool IFACE.getPending() { return IntPendGet(N); } \
        inline default async event void IFACE.interruptFired() { spurious_interrupt(N); }
    #include "CC26xxIntSources.h"
    #undef INT
}
