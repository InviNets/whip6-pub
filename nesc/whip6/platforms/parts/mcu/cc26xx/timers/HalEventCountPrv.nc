/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include <driverlib/timer.h>
#include <driverlib/gpio.h>

#define MAX_COUNT 0xffffff
#define TIMER_SIZE 16

generic module HalEventCountPrv(uint32_t pollingInterval) {
    provides interface EventCount as EvCntA;
    provides interface EventCount as EvCntB;

    uses interface EventCountConfig as EvCntAConfig @atmostonce();
    uses interface EventCountConfig as EvCntBConfig @atmostonce();

    uses interface CC26xxPin as PinA @atmostonce();
    uses interface CC26xxPin as PinB @atmostonce();

    uses interface CC26xxTimer @exactlyonce();
    uses interface ShareableOnOff as PowerDomain;
    uses interface AskBeforeSleep;

    uses interface Timer<TMilli, uint32_t>;
}

implementation {
    uint32_t running;  // mask of TIMER_A and TIMER_B
    // It counts events that occurred during previous timer runs. It is updated
    // only when timer overrun happens.
    unsigned long long overflows[2] = {0};
    // Value of timer that was read last time. It can be used as a cache after
    // stop - the value of the counter is written here immediately before the
    // stop.
    unsigned lastRead[2] = {0};

    unsigned int getCntIdx(uint32_t which) {
        return (which & TIMER_A) != 0;
    }

    uint32_t getTimerCountMode(uint32_t which) {
        event_count_mode_t mode = (which & TIMER_A) ? call EvCntAConfig.getMode()
                                                    : call EvCntBConfig.getMode();
        switch (mode) {
            case EVENT_COUNT_MODE_RISING_EDGE:
                return TIMER_EVENT_POS_EDGE;
            case EVENT_COUNT_MODE_FALLING_EDGE:
                return TIMER_EVENT_NEG_EDGE;
            case EVENT_COUNT_MODE_BOTH:
                return TIMER_EVENT_BOTH_EDGES;
            default:
                ASSERT(0);
                return 0; // otherwise it won't compile
        }
    }

    void pinEnable(uint32_t pinId, uint32_t which) {
        if (pinId != IOID_UNUSED) {
            uint32_t portId = IOC_PORT_MCU_PORT_EVENT0 +
                              (2 * call CC26xxTimer.number());
            if (which & TIMER_B)
                portId++;
            IOCPortConfigureSet(pinId, portId, IOC_STD_INPUT);
        }
    }

    void pinDisable(uint32_t pinId, uint32_t which) {
        if (pinId != IOID_UNUSED)
            IOCPinTypeGpioInput(pinId);
    }

    void startPeripheral() {
        uint32_t res = PRCM_PERIPH_TIMER0 + call CC26xxTimer.number();

        call PowerDomain.on();

        PRCMPeripheralRunEnable(res);
        PRCMPeripheralSleepEnable(res);
        PRCMPeripheralDeepSleepEnable(res);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;
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

    unsigned getTimerValue(uint32_t which) {
        if (running & which)
            return TimerValueGet(call CC26xxTimer.base(), which);
        else
            return lastRead[getCntIdx(which)];
    }

    unsigned long long readValue(uint32_t which) {
        unsigned long long ov_value;
        unsigned cnt_value;
        atomic {
            cnt_value = getTimerValue(which);
            if (cnt_value < lastRead[getCntIdx(which)])
                overflows[getCntIdx(which)] += MAX_COUNT;
            lastRead[getCntIdx(which)] = cnt_value;
            ov_value = overflows[getCntIdx(which)];
        }
        return ov_value + cnt_value;
    }

    error_t start(uint32_t which) {
        if (!running)
            startPeripheral();

        if (which & TIMER_A)
            pinEnable(call PinA.IOId(), TIMER_A);
        else
            pinEnable(call PinB.IOId(), TIMER_B);

        if (!running) {
            TimerConfigure(call CC26xxTimer.base(),
                TIMER_CFG_SPLIT_PAIR | TIMER_CFG_A_CAP_COUNT_UP |
                TIMER_CFG_B_CAP_COUNT_UP
            );
            TimerStallControl(call CC26xxTimer.base(), TIMER_BOTH, false);
        }

        TimerEventControl(call CC26xxTimer.base(), which, getTimerCountMode(which));

        TimerPrescaleMatchSet(call CC26xxTimer.base(), which, MAX_COUNT >> TIMER_SIZE);
        TimerMatchSet(call CC26xxTimer.base(), which, MAX_COUNT & ((1 << TIMER_SIZE) - 1));

        TimerEnable(call CC26xxTimer.base(), which);

        if (!running)
            call Timer.startWithTimeoutFromNow(pollingInterval);

        atomic running |= which;

        return SUCCESS;
    }

    error_t stop(uint32_t which) {
        readValue(which); // for caching current value
        atomic running &= ~which;
        if (!running)
            call Timer.stop();

        TimerDisable(call CC26xxTimer.base(), which);

        if (which & TIMER_A)
            pinDisable(call PinA.IOId(), TIMER_A);
        else
            pinDisable(call PinB.IOId(), TIMER_B);

        if (!running)
            stopPeripheral();

        return SUCCESS;
    }

    event void Timer.fired() {
        call Timer.startWithTimeoutFromLastTrigger(pollingInterval);
        if (running & TIMER_A)
            readValue(TIMER_A);
        if (running & TIMER_B)
            readValue(TIMER_B);
    }

    command error_t EvCntA.start() {
        return start(TIMER_A);
    }

    command error_t EvCntB.start() {
        return start(TIMER_B);
    }

    command error_t EvCntA.stop() {
        return stop(TIMER_A);
    }

    command error_t EvCntB.stop() {
        return stop(TIMER_B);
    }

    command error_t EvCntA.read(unsigned long long *value) {
        *value = readValue(TIMER_A);
        return SUCCESS;
    }

    command error_t EvCntB.read(unsigned long long *value) {
        *value = readValue(TIMER_B);
        return SUCCESS;
    }

    event void PinA.configure() {
        pinDisable(call PinA.IOId(), TIMER_A);
    }

    event void PinB.configure() {
        pinDisable(call PinB.IOId(), TIMER_B);
    }

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return running ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }

    default async command uint32_t PinA.IOId() {
        return IOID_UNUSED;
    }

    default async command uint32_t PinB.IOId() {
        return IOID_UNUSED;
    }

    default command event_count_mode_t EvCntAConfig.getMode() {
        return EVENT_COUNT_MODE_RISING_EDGE;
    }

    default command event_count_mode_t EvCntBConfig.getMode() {
        return EVENT_COUNT_MODE_RISING_EDGE;
    }
}
