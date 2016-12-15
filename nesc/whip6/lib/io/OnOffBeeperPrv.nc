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

generic module OnOffBeeperPrv(uint32_t beepTimeMs,
        uint32_t shortestBeepTimeMs) {
    provides interface Beeper;
    uses interface OnOffSwitch;
    uses interface Timer<TMilli, uint32_t>;
}
implementation {
    bool busy = FALSE;
    bool on = FALSE;

    const char_code* beepSequence = NULL;
    uint8_t beepsRemaining;

    void setTimeout(uint8_t mult) {
        if (mult == 0) {
            call Timer.startWithTimeoutFromNow(shortestBeepTimeMs);
        } else {
            call Timer.startWithTimeoutFromNow(beepTimeMs * mult);
        }
    }

    void switchOn() {
        call OnOffSwitch.on();
        on = TRUE;
    }

    void switchOff() {
        call OnOffSwitch.off();
        on = FALSE;
    }

    void updateState() {
        if (on) {
            switchOff();
            setTimeout(1);
        } else if (beepSequence != NULL) {
            if (*beepSequence >= '0' && *beepSequence <= '9') {
                setTimeout(*beepSequence - '0');
            } else {
                panic("Invalid beep sequence character");
                return;
            }
            switchOn();
            beepSequence++;
            if (*beepSequence == '\0') {
                beepSequence = NULL;
                busy = FALSE;
            }
        } else if (beepsRemaining > 0) {
            switchOn();
            setTimeout(1);
            beepsRemaining--;
            if (beepsRemaining == 0) {
                busy = FALSE;
            }
        }
    }

    command error_t Beeper.beep(uint8_t numBeeps) {
        if (busy) {
            return EBUSY;
        }
        busy = TRUE;
        beepsRemaining = numBeeps;
        updateState();
        return SUCCESS;
    }

    command error_t Beeper.beepSequence(const char_code* sequence) {
        if (busy) {
            return EBUSY;
        }
        if (sequence == NULL) {
            return EINVAL;
        }
        busy = TRUE;
        beepSequence = sequence;
        updateState();
        return SUCCESS;
    }

    event void Timer.fired() {
        updateState();
    }
}
