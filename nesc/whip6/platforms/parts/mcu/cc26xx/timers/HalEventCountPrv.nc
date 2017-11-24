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

#define MAX_COUNT 0x800
#define TIMER_SIZE 16

generic module HalEventCountPrv() {
    provides interface EventCount<uint64_t> as EvCntA;
    provides interface EventCount<uint64_t> as EvCntB;

    uses interface EventCountConfig as EvCntAConfig @atmostonce();
    uses interface EventCountConfig as EvCntBConfig @atmostonce();

    uses interface CC26xxPin as PinA @atmostonce();
    uses interface CC26xxPin as PinB @atmostonce();

    uses interface CC26xxTimer @exactlyonce();
    uses interface ExternalEvent as ChannelAInterrupt;
    uses interface ExternalEvent as ChannelBInterrupt;
    uses interface ShareableOnOff as PowerDomain;
    uses interface AskBeforeSleep;
}

implementation {
    uint32_t running;  // mask of TIMER_A and TIMER_B
    // It counts events that occurred during previous timer runs. It is updated
    // only when timer overrun happens.
    uint64_t overflows[2] = {0};
    // Value of timer that was read last time. It can be used as a cache after
    // stop - the value of the counter is written here immediately before the
    // stop.
    uint32_t lastRead[2] = {0};

    uint32_t getCntIdx(uint32_t which) {
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

    uint32_t getTimerValue(uint32_t which) {
        if (running & which)
            return TimerValueGet(call CC26xxTimer.base(), which);
        else
            return lastRead[getCntIdx(which)];
    }

    uint64_t readValue(uint32_t which) {
        uint64_t ov_value;
        uint32_t cnt_value;
        atomic {
            cnt_value = getTimerValue(which) & (MAX_COUNT - 1);
            if (which & TIMER_A) {
                if (call ChannelAInterrupt.getPending() |
                        (TimerIntStatus(call CC26xxTimer.base(), TRUE) & TIMER_CAPA_MATCH)) {
                    cnt_value = getTimerValue(TIMER_A) | MAX_COUNT;
                }
            }
            if (which & TIMER_B) {
                if (call ChannelBInterrupt.getPending() |
                        (TimerIntStatus(call CC26xxTimer.base(), TRUE) & TIMER_CAPB_MATCH)) {
                    cnt_value = getTimerValue(TIMER_B) | MAX_COUNT;
                }
            }
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

        if (which & TIMER_A) {
            call ChannelAInterrupt.asyncNotifications(TRUE);
            TimerIntEnable(call CC26xxTimer.base(), TIMER_CAPA_MATCH);

        } else {
            call ChannelBInterrupt.asyncNotifications(TRUE);
            TimerIntEnable(call CC26xxTimer.base(), TIMER_CAPB_MATCH);
        }

        TimerEnable(call CC26xxTimer.base(), which);


        atomic running |= which;

        return SUCCESS;
    }

    error_t stop(uint32_t which) {
        readValue(which); // for caching current value
        atomic running &= ~which;

        TimerDisable(call CC26xxTimer.base(), which);

        if (which & TIMER_A) {
            call ChannelAInterrupt.asyncNotifications(FALSE);
        } else {
            call ChannelBInterrupt.asyncNotifications(FALSE);
        }

        if (which & TIMER_A)
            pinDisable(call PinA.IOId(), TIMER_A);
        else
            pinDisable(call PinB.IOId(), TIMER_B);

        if (!running)
            stopPeripheral();

        return SUCCESS;
    }

    event async void ChannelAInterrupt.triggered() {
        atomic {
            call ChannelAInterrupt.clearPending();
            TimerIntClear(call CC26xxTimer.base(), TIMER_CAPA_MATCH);
            overflows[getCntIdx(TIMER_A)] += MAX_COUNT;
        }
    }

    event async void ChannelBInterrupt.triggered() {
        atomic {
            call ChannelBInterrupt.clearPending();
            TimerIntClear(call CC26xxTimer.base(), TIMER_CAPB_MATCH);
            overflows[getCntIdx(TIMER_B)] += MAX_COUNT;
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

    command error_t EvCntA.read(uint64_t *value) {
        *value = readValue(TIMER_A);
        return SUCCESS;
    }

    command error_t EvCntB.read(uint64_t *value) {
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
