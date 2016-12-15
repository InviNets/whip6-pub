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

generic module BothEdgesDebouncerPub(uint16_t debounceTimeMs) {
    uses interface ExternalEvent;
    uses interface Timer<TMilli, uint32_t>;
    uses interface Button as HalButton;

    provides interface ButtonPress;
    provides interface Button;
}
implementation {
    enum {
        NUM_SAMPLES = 3,
    };

    typedef enum {
        STATE_DISABLED,
        STATE_IDLE,
        STATE_SAMPLING,
    } state_t;

    state_t state;
    bool pressed;
    int8_t counter;

    void startIdle() {
        state = STATE_IDLE;
        call Timer.stop();
        call ExternalEvent.clearPending();
        call ExternalEvent.asyncNotifications(TRUE);
    }

    void sample() {
        bool halPressed = call HalButton.isPressed();

        if (halPressed == pressed) {
            counter--;
        } else {
            counter++;
        }

        if (counter < 0) {
            startIdle();
        } else if (counter >= NUM_SAMPLES) {
            startIdle();
            pressed = halPressed;
            if (pressed) {
                signal ButtonPress.buttonPressed();
            } else {
                signal ButtonPress.buttonReleased();
            }
        }

    }

    task void startSampling() {
        if (state != STATE_IDLE) {
            return;
        }

        state = STATE_SAMPLING;
        counter = 0;
        call ExternalEvent.asyncNotifications(FALSE);
        call ExternalEvent.clearPending();
        call Timer.startWithTimeoutFromNow(debounceTimeMs / NUM_SAMPLES);
        sample();
    }

    command void ButtonPress.enable() {
        call Timer.stop();
        call ExternalEvent.clearPending();
        call ExternalEvent.asyncNotifications(TRUE);
        pressed = FALSE;
        state = STATE_IDLE;
    }

    command void ButtonPress.disable() {
        if (pressed) {
            signal ButtonPress.buttonReleased();
        }
        pressed = FALSE;
        state = STATE_DISABLED;
        call Timer.stop();
        call ExternalEvent.asyncNotifications(FALSE);
        call ExternalEvent.clearPending();
    }

    event void Timer.fired() {
        if (state != STATE_SAMPLING) {
            panic();
        }

        call Timer.startWithTimeoutFromLastTrigger(debounceTimeMs / NUM_SAMPLES);
        sample();
    }

    command bool Button.isPressed() {
        return pressed;
    }

    async event void ExternalEvent.triggered() {
        post startSampling();
    }

    default event void ButtonPress.buttonPressed() {}
    default event void ButtonPress.buttonReleased() {}
}
