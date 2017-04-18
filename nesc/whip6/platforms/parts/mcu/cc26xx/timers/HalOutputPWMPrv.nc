/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <stdio.h>
#include <driverlib/ioc.h>
#include <driverlib/timer.h>
#include <driverlib/prcm.h>

//#define DBGPRINTF printf
#define DBGPRINTF(...)

generic module HalOutputPWMPrv() {
    provides interface OutputPWM as PWMA;
    provides interface OutputPWM as PWMB;

    uses interface OutputPWMConfig as PWMAConfig @atmostonce();
    uses interface OutputPWMConfig as PWMBConfig @atmostonce();

    uses interface CC26xxPin as PinA @atmostonce();
    uses interface CC26xxPin as PinB @atmostonce();

    uses interface CC26xxTimer @exactlyonce();
    uses interface ShareableOnOff as PowerDomain;
    uses interface AskBeforeSleep;
}

implementation {
    uint32_t running;  // mask of TIMER_A and TIMER_B

    void pinAEnable() {
        if (call PinA.IOId() != IOID_UNUSED) {
            IOCPortConfigureSet(call PinA.IOId(),
                    IOC_PORT_MCU_PORT_EVENT0 +
                        (2 * call CC26xxTimer.number()),
                    IOC_STD_OUTPUT);
        }
    }

    void pinADisable() {
        if (call PinA.IOId() != IOID_UNUSED) {
            IOCPinTypeGpioOutput(call PinA.IOId());
            if (call PWMAConfig.shouldBeHighWhenStopped()) {
                GPIO_setDio(call PinA.IOId());
            } else {
                GPIO_clearDio(call PinA.IOId());
            }
        }
    }

    event void PinA.configure() {
        pinADisable();
    }

    default async command uint32_t PinA.IOId() {
        return IOID_UNUSED;
    }

    void pinBEnable() {
        if (call PinB.IOId() != IOID_UNUSED) {
            IOCPortConfigureSet(call PinB.IOId(),
                    IOC_PORT_MCU_PORT_EVENT0 +
                        (2 * call CC26xxTimer.number()),
                    IOC_STD_OUTPUT);
        }
    }

    void pinBDisable() {
        if (call PinB.IOId() != IOID_UNUSED) {
            IOCPinTypeGpioOutput(call PinB.IOId());
            if (call PWMBConfig.shouldBeHighWhenStopped()) {
                GPIO_setDio(call PinB.IOId());
            } else {
                GPIO_clearDio(call PinB.IOId());
            }
        }
    }

    event void PinB.configure() {
        pinBDisable();
    }

    default async command uint32_t PinB.IOId() {
        return IOID_UNUSED;
    }

    void startPeripheral() {
        uint32_t res = PRCM_PERIPH_TIMER0 + call CC26xxTimer.number();

        call PowerDomain.on();

        PRCMPeripheralRunEnable(res);
        PRCMPeripheralSleepEnable(res);
        PRCMPeripheralDeepSleepEnable(res);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        TimerConfigure(call CC26xxTimer.base(),
                TIMER_CFG_SPLIT_PAIR | TIMER_CFG_A_PWM | TIMER_CFG_B_PWM);
        TimerStallControl(call CC26xxTimer.base(), TIMER_BOTH, false);
    }

    void stopPeripheral() {
        uint32_t res = PRCM_PERIPH_TIMER0 + call CC26xxTimer.number();
        PRCMPeripheralRunDisable(res);
        PRCMPeripheralSleepDisable(res);
        PRCMPeripheralDeepSleepDisable(res);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        call PowerDomain.off();
    }

    uint32_t computeLoadValue(uint16_t hz) {
        uint32_t loadValue = SysCtrlClockGet() / hz - 1;
        if (loadValue >= (1UL << 24)) {
            loadValue = (1UL << 24) - 1;
        }
        return loadValue;
    }

    uint32_t computeMatchValue(uint32_t load, uint8_t percent) {
        /* We never generate MATCH == 0, which would output 1 clock of low
         * signal every period. We generate 100%-high state for
         * percent == 100. */
        if (percent == 100) {
            // See "Figure 13-5. CCP Output, GPT:TnMATCHR > GPT:TnILR"
            return load + 1;
        }
        return load * (100 - percent) / 100;
    }

    error_t start(uint32_t which, uint8_t percent, uint16_t hz) {
        uint32_t load, match;

        if (percent > 100) {
            return EINVAL;
        }

        if (!running) {
            startPeripheral();
        }
        running |= which;

        if (which & TIMER_A) {
            pinAEnable();
        }
        if (which & TIMER_B) {
            pinBEnable();
        }

        load = computeLoadValue(hz);
        match = computeMatchValue(load, percent);
        DBGPRINTF("[HalOutputPWMPrv-%d%c] start: load=%lu, match=%lu\r\n",
                call CC26xxTimer.number(),
                (which & TIMER_A) ? 'A' : 'B',
                load, match);
        TimerPrescaleSet(call CC26xxTimer.base(), which, load >> 16);
        TimerLoadSet(call CC26xxTimer.base(), which, load & 0xffff);
        TimerPrescaleMatchSet(call CC26xxTimer.base(), which, match >> 16);
        TimerMatchSet(call CC26xxTimer.base(), which, match & 0xffff);
        TimerEnable(call CC26xxTimer.base(), which);

        return SUCCESS;
    }

    command error_t PWMA.start(uint8_t percent, uint16_t hz) {
        return start(TIMER_A, percent, hz);
    }

    command error_t PWMB.start(uint8_t percent, uint16_t hz) {
        return start(TIMER_B, percent, hz);
    }

    error_t stop(uint32_t which) {
        DBGPRINTF("[HalOutputPWMPrv-%d%c] stop.\r\n",
                call CC26xxTimer.number(),
                (which & TIMER_A) ? 'A' : 'B');
        TimerDisable(call CC26xxTimer.base(), which);

        if (which & TIMER_A) {
            pinADisable();
        }
        if (which & TIMER_B) {
            pinBDisable();
        }

        running &= ~which;
        if (!running) {
            stopPeripheral();
        }

        return SUCCESS;
    }

    command error_t PWMA.stop() {
        return stop(TIMER_A);
    }

    command error_t PWMB.stop() {
        return stop(TIMER_B);
    }

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return running ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }

    default command bool PWMAConfig.shouldBeHighWhenStopped() { return FALSE; }
    default command bool PWMBConfig.shouldBeHighWhenStopped() { return FALSE; }
}

#undef DBGPRINTF
