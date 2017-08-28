/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

generic module BistableRelayOnOffSwitchPrv(uint32_t impulseLengthMs) {
    uses interface OnOffSwitch as SetSwitch;
    uses interface OnOffSwitch as ResetSwitch;
    uses interface Timer<TMilli, uint32_t>;
    provides interface OnOffSwitch as OnOff;
}
implementation{
    typedef enum {
        STATE_UNKNOWN,
        STATE_OFF,
        STATE_ON
    } state_t;

    state_t state = STATE_UNKNOWN;

    command error_t OnOff.on() {
        error_t err;
        if (state == STATE_ON) {
            return EALREADY;
        }
        if ((err = call ResetSwitch.off()) != SUCCESS) {
            goto out;
        }
        if ((err = call SetSwitch.on()) != SUCCESS) {
            goto out;
        }
        state = STATE_ON;
        call Timer.startWithTimeoutFromNow(impulseLengthMs);
out:
        return err;
    }

    command error_t OnOff.off() {
        error_t err;
        if (state == STATE_OFF) {
            return EALREADY;
        }
        if ((err = call SetSwitch.off()) != SUCCESS) {
            goto out;
        }
        if ((err = call ResetSwitch.on()) != SUCCESS) {
            goto out;
        }
        state = STATE_OFF;
        call Timer.startWithTimeoutFromNow(impulseLengthMs);
out:
        return err;
    }

    event void Timer.fired() {
        error_t err = ecombine(call SetSwitch.off(), call ResetSwitch.off());
        if (err != SUCCESS) {
            panic("Cannot release relay action switch");
        }
    }

}
