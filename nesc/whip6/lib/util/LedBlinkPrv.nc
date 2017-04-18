/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

generic module LedBlinkPrv() {
    uses interface Led;
    uses interface Timer<TMilli, uint32_t> @exactlyonce();

    provides interface LedBlink;
}

implementation {
    enum {
        STATE_IDLE,
        STATE_ONCE,
        STATE_BLINK,
    } state = STATE_IDLE;

    bool ledOn = FALSE;
    uint32_t currBlinkMs, currBreakMs;

    command error_t LedBlink.blinkOnce(uint32_t timeMs) {
        if(state != STATE_IDLE) {
            return EBUSY;
        }
        state = STATE_ONCE;
        currBlinkMs = timeMs;
        call Led.on();
        ledOn = TRUE;
        call Timer.startWithTimeoutFromNow(timeMs);
        return SUCCESS;
    }

    event void Timer.fired() {
        switch(state) {
            case STATE_IDLE: /* may happen if stopBlinking is called when the task is already posted */
                break;
            case STATE_ONCE:
                call Led.off();
                state = STATE_IDLE;
                signal LedBlink.blinkOnceDone(currBlinkMs, SUCCESS);
                break;
            case STATE_BLINK:
                if(ledOn) {
                    call Led.off();
                    call Timer.startWithTimeoutFromLastTrigger(currBreakMs);
                } else {
                    call Led.on();
                    call Timer.startWithTimeoutFromLastTrigger(currBlinkMs);
                }
                ledOn = !ledOn;
                break;
        }
    }

    command error_t LedBlink.startBlinking(uint32_t periodBlinkMs, uint32_t periodBreakMs) {
        if(state != STATE_IDLE) {
            return EBUSY;
        }
        state = STATE_BLINK;
        currBlinkMs = periodBlinkMs;
        currBreakMs = periodBreakMs;
        call Led.on();
        ledOn = TRUE;
        call Timer.startWithTimeoutFromNow(periodBlinkMs);
        return SUCCESS;
    }

    command error_t LedBlink.stopBlinking() {
        if(state != STATE_BLINK) {
            return EALREADY;
        }
        call Timer.stop();
        call Led.off();
        ledOn = FALSE;
        state = STATE_IDLE;
        return SUCCESS;
    }

    default event void LedBlink.blinkOnceDone(uint32_t timeMs, error_t error) {}
}
