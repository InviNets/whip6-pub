/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

generic module TwoButtonsTogetherPrv(uint32_t maxDifferenceMs) {
    provides interface ButtonPress;

    uses interface ButtonPress as Button1;
    uses interface ButtonPress as Button2;

    uses interface Timer<TMilli, uint32_t>;
}
implementation {
    bool enabled;

    uint32_t b1LastPress;
    uint32_t b2LastPress;

    command void ButtonPress.enable() {
        call Button1.enable();
        call Button2.enable();
    }

    command void ButtonPress.disable() {
        call Button2.disable();
        call Button1.disable();
    }

    event void Button1.buttonPressed() {
        b1LastPress = call Timer.getNow();
        if (b1LastPress - b2LastPress < maxDifferenceMs) {
            signal ButtonPress.buttonPressed();
            signal ButtonPress.buttonReleased();
        }
    }

    event void Button2.buttonPressed() {
        b2LastPress = call Timer.getNow();
        if (b2LastPress - b1LastPress < maxDifferenceMs) {
            signal ButtonPress.buttonPressed();
            signal ButtonPress.buttonReleased();
        }
    }

    inline event void Button1.buttonReleased() { }
    inline event void Button2.buttonReleased() { }
    inline event void Timer.fired() { }

    default event void ButtonPress.buttonPressed() {}
    default event void ButtonPress.buttonReleased() {}
}
