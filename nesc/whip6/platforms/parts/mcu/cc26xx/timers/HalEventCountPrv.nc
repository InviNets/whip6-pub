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

#define MAX_COUNT 0xffff

generic module HalEventCountPrv() {
    provides interface EventCount as EvCntA;
    provides interface EventCount as EvCntB;

    uses interface EventCountConfig as EvCntAConfig @atmostonce();
    uses interface EventCountConfig as EvCntBConfig @atmostonce();

    uses interface CC26xxPin as PinA @atmostonce();
    uses interface CC26xxPin as PinB @atmostonce();

    uses interface CC26xxTimer @exactlyonce();
    uses interface ShareableOnOff as PowerDomain;
    uses interface AskBeforeSleep;

    uses interface ExternalEvent as ChannelAInterrupt @atmostonce();
    uses interface ExternalEvent as ChannelBInterrupt @atmostonce();
}

implementation {
    uint32_t running;  // mask of TIMER_A and TIMER_B
    // It counts events that occurred during previous timer runs. It is updated
    // only when timer overrun happens.
    unsigned long long evCnt[2] = {0};
    // Value of timer used when the timer is stopped. Otherwise the timer
    // register should be read.
    unsigned cachedTimer[2] = {0};

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

    error_t start(uint32_t which) {
        uint32_t flags = 0;

        if (!running)
            startPeripheral();

        if (which & TIMER_A) {
            pinEnable(call PinA.IOId(), TIMER_A);
            flags = TIMER_CAPA_MATCH;
            call ChannelAInterrupt.clearPending();
            call ChannelAInterrupt.asyncNotifications(TRUE);
        }
        else {
            pinEnable(call PinB.IOId(), TIMER_B);
            flags = TIMER_CAPB_MATCH;
            call ChannelBInterrupt.clearPending();
            call ChannelBInterrupt.asyncNotifications(TRUE);
        }

        if (!running) {
            TimerConfigure(call CC26xxTimer.base(),
                TIMER_CFG_SPLIT_PAIR | TIMER_CFG_A_CAP_COUNT_UP |
                TIMER_CFG_B_CAP_COUNT_UP
            );
            TimerStallControl(call CC26xxTimer.base(), TIMER_BOTH, false);
        }

        TimerEventControl(call CC26xxTimer.base(), which, getTimerCountMode(which));

        // Since there's no way to atomically read both 16-bit timer and prescaler
        // value, we'll not use the prescaler.
        TimerPrescaleMatchSet(call CC26xxTimer.base(), which, 0);
        TimerMatchSet(call CC26xxTimer.base(), which, MAX_COUNT);

        TimerIntEnable(call CC26xxTimer.base(), flags);
        TimerEnable(call CC26xxTimer.base(), which);

        running |= which;

        return SUCCESS;
    }

    error_t stop(uint32_t which) {
        cachedTimer[getCntIdx(which)] = TimerValueGet(call CC26xxTimer.base(), which);

        TimerDisable(call CC26xxTimer.base(), which);
        TimerIntDisable(call CC26xxTimer.base(),
                        (which & TIMER_A) ? TIMER_CAPA_MATCH : TIMER_CAPB_MATCH);

        if (which & TIMER_A)
            pinDisable(call PinA.IOId(), TIMER_A);
        else
            pinDisable(call PinB.IOId(), TIMER_B);

        running &= ~which;
        if (!running)
            stopPeripheral();

        return SUCCESS;
    }

    unsigned getTimerValue(uint32_t which) {
        if (!running)
            return cachedTimer[getCntIdx(which)];
        else
            return TimerValueGet(call CC26xxTimer.base(), which);
    }

    unsigned long long readValue(uint32_t which, unsigned long long *res) {
        unsigned long long value;
        unsigned read_value;
        atomic {
            // We have to be really careful here to avoid race conditions.
            // The main problem is non-atomicity of reading the pair:
            // (timer value, evCnt). It wouldn't be a problem if timer stopped
            // after reaching MAX_COUNT but then we would loose some events.
            // Atomic statement will block the interrupt from updating evCnt
            // in between the reads.
            // However, an overflow can still happen and we have to check it
            // manually.
            read_value = getTimerValue(which);
            value = evCnt[getCntIdx(which)];
            if (getTimerValue(which) < read_value)
                value += MAX_COUNT;
        }
        *res = value + read_value;
        return SUCCESS;
    }

    void InterruptHandler(uint32_t which) {
        uint32_t status;
        uint32_t interruptMask;

        status = TimerIntStatus(call CC26xxTimer.base(), true);
        if (which & TIMER_A)
            interruptMask = TIMER_CAPA_MATCH;
        else
            interruptMask = TIMER_CAPB_MATCH;

        if (status & interruptMask) {
            TimerIntClear(call CC26xxTimer.base(), interruptMask);
            TimerIntStatus(call CC26xxTimer.base(), true); // for write propagation
            // Now we require at least two system cycles before returning
            atomic evCnt[getCntIdx(which)] += MAX_COUNT;
        }
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
        return readValue(TIMER_A, value);
    }

    command error_t EvCntB.read(unsigned long long *value) {
        return readValue(TIMER_B, value);
    }

    async event void ChannelAInterrupt.triggered() {
        InterruptHandler(TIMER_A);
    }

    async event void ChannelBInterrupt.triggered() {
        InterruptHandler(TIMER_B);
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
