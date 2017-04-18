/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic module LongButtonPressPrv(uint16_t timeMs) {
    provides interface ButtonPress;
    uses interface ButtonPress as SubButtonPress;
    uses interface Timer<TMilli, uint32_t>;
}
implementation {
    enum {
        POLL_INTERVAL_MS = 10,
        NUM_POLLS_TO_CONSIDER_RELEASED = 3,
    };

    bool enabled;
    bool pressed;
    uint8_t remainingPollsToRelease;
    uint16_t remainingPollsToPress;

    void stop() {
        call Timer.stop();
        if (pressed) {
            pressed = FALSE;
            signal ButtonPress.buttonReleased();
        }
    }

    event void SubButtonPress.buttonPressed() {
        if (enabled) {
            call Timer.startWithTimeoutFromNow(timeMs);
        }
    }

    event void SubButtonPress.buttonReleased() {
        if (enabled) {
            stop();
        }
    }

    event void Timer.fired() {
        if (enabled) {
            pressed = TRUE;
            signal ButtonPress.buttonPressed();
        }
    }

    command void ButtonPress.enable() {
        /* We do not eneable SubButtonPress here, as it is probably used
         * by another component as well, and it's better not have two
         * components calling enable/disable without synchronization.
         */
        enabled = TRUE;
    }

    command void ButtonPress.disable() {
        stop();
        enabled = FALSE;
    }

    default event void ButtonPress.buttonPressed() {}
    default event void ButtonPress.buttonReleased() {}
}
