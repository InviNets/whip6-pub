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
 * @author Szymon Acedanski
 */

#include <driverlib/trng.h>

generic module HalTRNGPrv(bool secure) {
    provides interface Random;

    uses interface ShareableOnOff as PeriphDomain;
}

implementation {
    enum {
        MIN_SAMPLES_PER_CYCLE = 255,
        MAX_SAMPLES_PER_CYCLE = 255,
        CLOCKS_PER_SAMPLE = 1,
    };

    command uint32_t Random.rand32() {
        uint32_t value;

        call PeriphDomain.on();

        PRCMPeripheralRunEnable(PRCM_PERIPH_TRNG);
        PRCMPeripheralSleepEnable(PRCM_PERIPH_TRNG);
        PRCMPeripheralDeepSleepEnable(PRCM_PERIPH_TRNG);

        PRCMLoadSet();
        while(!PRCMLoadGet()) /* nop */;

        if (secure) {
            TRNGConfigure(0, 0, 15);
        } else {
            TRNGConfigure(255, 255, 1);
        }
        TRNGEnable();
        while (!(TRNGStatusGet() & TRNG_NUMBER_READY)) /* nop */;
        value = TRNGNumberGet(TRNG_LOW_WORD);

        PRCMPeripheralRunDisable(PRCM_PERIPH_TRNG);
        PRCMPeripheralSleepDisable(PRCM_PERIPH_TRNG);
        PRCMPeripheralDeepSleepDisable(PRCM_PERIPH_TRNG);
        PRCMLoadSet();

        call PeriphDomain.off();

        return value;
    }

    command uint16_t Random.rand16() {
        return (uint16_t)call Random.rand32();
    }
}
