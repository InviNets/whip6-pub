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
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include <driverlib/gpio.h>
#include <driverlib/aon_rtc.h>
#include <driverlib/sys_ctrl.h>
#include "Assert.h"

module HalCC26xxRTCPrv {
    provides interface Init @exactlyonce();
    provides interface Timer<T32khz, uint32_t> @atmostonce();
    provides interface TimerOverflow;
    provides interface AsyncCounter<T32khz, uint32_t>;
    provides interface AsyncCounter<T32khz, uint64_t> as AsyncCounter64;

    uses interface ExternalEvent as RTCInterrupt;
    uses interface CC26xxWakeUpSource as WakeUpSource;
    uses interface AskBeforeSleep;
}
implementation {
    // TODO: well, consider rewriting this from scratch as it contains a lot of
    //       unneeded logic, copied from CC253x.

    enum {
        // The docs say 2 SCLK_LF clocks, but let's make it 3 if at some point
        // we decide to use drift correction etc.
        MIN_TIMEOUT = 3,

        // If we would trigger in less that this many ticks,
        // only IDLE sleep is allowed.
        MIN_TIMEOUT_FOR_DEEP_SLEEP = 6,
    };

    bool running = FALSE;
    uint32_t startTime;
    uint32_t timeoutFromStartTime;
    uint32_t lastTrigger;
    uint32_t lastNow;
    uint32_t nextEvent;

    task void timerEvent();

    int32_t compareTime(uint32_t a, uint32_t b) {
        return (int32_t)(a - b);
    }

    void arm() {
        atomic {
            uint32_t earliestPossible;

            SysCtrlAonSync();

            // The timer promises to fire with the compare value up to 1 second
            // in the past, but there is also another note:
            // "Note that a new event can not occur on this channel in first 2
            //  SCLK_LF cycles after a clearance."
            earliestPossible = call Timer.getNow() + MIN_TIMEOUT;
            nextEvent = startTime + timeoutFromStartTime;
            if (compareTime(earliestPossible, nextEvent) > 0) {
                nextEvent = earliestPossible;
            }

            // "Be careful when configuring a new compare value if the new
            // value is near, because clearing an RTC event takes precedence
            // over setting an event." -- swra486.pdf, Section 4.7.2
            AONRTCCompareValueSet(AON_RTC_CH0, nextEvent << 1);

            /*if (earliestPossible > 164074 && timeoutFromStartTime != 0x80000000) {
                printf("[HalRTC] Armed: %u, now=%u, st=%u, delta=%u\r\n",
                        nextEvent, earliestPossible, startTime,
                        timeoutFromStartTime);
            }*/
        }
    }

    command error_t Init.init() {
        call WakeUpSource.enableWakeUp();
        AONRTCEnable();

        atomic {
          lastNow = 0;
        }

        arm();

        AONRTCEventClear(AON_RTC_CH0 | AON_RTC_CH1 | AON_RTC_CH2);
        AONRTCChannelEnable(AON_RTC_CH0);
        AONRTCCombinedEventConfig(AON_RTC_CH0);
        AONRTCDelayConfig(AON_RTC_CONFIG_DELAY_NODELAY);

        call RTCInterrupt.asyncNotifications(TRUE);

        return SUCCESS;
    }

    void scheduleStoppedTimer() {
        CHECK(running == FALSE);
        // Fire at least once every half the overflow period, to keep the
        // overflow events running.
        startTime = call Timer.getNow();
        // Plenty of margin to not overflow signed arithmetic.
        timeoutFromStartTime = 0x70000000;
        arm();
    }

    task void timerEvent() {
        if (running) {
            uint32_t now = call Timer.getNow();
            uint32_t elapsed = now - startTime;
            if (elapsed >= timeoutFromStartTime) {
                //printf("[HalRTC] fire!\r\n");
                running = FALSE;
                lastTrigger = startTime + timeoutFromStartTime;
                signal Timer.fired();
            }
        }

        if (!running) {
            scheduleStoppedTimer();
        }
    }

    command void Timer.startWithTimeoutFromNow(uint32_t dt) {
        startTime = call Timer.getNow();
        timeoutFromStartTime = dt;
        running = TRUE;
        arm();
    }

    command void Timer.startWithTimeoutFromLastTrigger(uint32_t dt) {
        startTime = lastTrigger;
        timeoutFromStartTime = dt;
        running = TRUE;
        arm();
    }

    command void Timer.startWithTimeoutFromTime(uint32_t t0, uint32_t dt) {
        startTime = t0;
        timeoutFromStartTime = dt;
        running = TRUE;
        arm();
    }

    command void Timer.stop() {
        running = FALSE;
        //printf("[HalRTC] Stopped\r\n");
        scheduleStoppedTimer();
    }

    command bool Timer.isRunning() {
        return running;
    }

    command uint32_t Timer.getLastTrigger() {
        return lastTrigger;
    }

    command uint32_t Timer.getNow() {
        uint32_t now = call AsyncCounter.getNow();
        bool signal_overflow = FALSE;
        atomic {
            if (now < lastNow) {
                signal_overflow = TRUE;
            }
            lastNow = now;
        }
        if (signal_overflow) {
            signal TimerOverflow.overflow();
        }
        return now;
    }

    command uint32_t Timer.getStartTime() {
        return startTime;
    }

    command uint32_t Timer.getTimeoutFromStartTime() {
        return timeoutFromStartTime;
    }

    async inline command uint32_t AsyncCounter.getNow() {
        return AONRTCCurrent64BitValueGet() >> 17;
    }

    async inline command uint64_t AsyncCounter64.getNow() {
        // No overflow handling, sorry, that's still 46 bits left,
        // which is 2**32 seconds...
        return AONRTCCurrent64BitValueGet() >> 17;
    }

    async event void RTCInterrupt.triggered() {
        AONRTCEventClear(AON_RTC_CH0);
        post timerEvent();
    }

    event inline sleep_level_t AskBeforeSleep.maxSleepLevel() {
        uint32_t now = call Timer.getNow();
        int32_t delta = compareTime(nextEvent, now);
        return (delta >= MIN_TIMEOUT_FOR_DEEP_SLEEP) ? SLEEP_LEVEL_DEEP
            : SLEEP_LEVEL_IDLE;
    }

    default event void Timer.fired() { }
    default event void TimerOverflow.overflow() { }
}
