/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


module PanicPrv {
    uses interface Led[uint8_t id];
    uses interface BusyWait<TMicro, uint16_t>;
    uses interface Reset;
    uses interface PanicHook;
} implementation{
    enum {
        PANIC_REPLAYS = 3,
        LONG_BLINK_WAIT_MS = 400,
        SHORT_BLINK_WAIT_MS = 160,
        LONG_PAUSE_MS = 1600,
        SHORT_PAUSE_MS = 900,
    };

    void blinkSos();
    void blinkNumber(uint16_t n);
    void longBlink();
    void shortBlink();
    void on();
    void off();
    void wait(uint16_t ms);
    void longPause();
    void shortPause();

    void _panic(uint16_t panicId) @spontaneous() @C() {
        int i;
        call PanicHook.willPanic(panicId);
        for(i = 0; i < PANIC_REPLAYS; i++) {
            blinkSos();
            longPause();
            blinkNumber(panicId);
            longPause();
        }
        call Reset.reset();
    }

    void blinkSos() {
        int i;
        for (i = 0; i < 3; i++)
            shortBlink();
        for (i = 0; i < 3; i++)
            longBlink();
        for (i = 0; i < 3; i++)
            shortBlink();
    }

    void blinkNumber(uint16_t n) {
        uint16_t mask = 10000;

        if (n == 0) return;

        while (mask > n)
            mask /= 10;

        while (n != 0) {
            int d = n / mask;
            n %= mask;
            mask /= 10;

            while(d--) {
                longBlink();
                wait(LONG_BLINK_WAIT_MS);
            }
            shortPause();
        }
    }

    void longBlink() {
        on();
        wait(LONG_BLINK_WAIT_MS);
        off();
        wait(SHORT_BLINK_WAIT_MS);
    }

    void shortBlink() {
        on();
        wait(SHORT_BLINK_WAIT_MS);
        off();
        wait(SHORT_BLINK_WAIT_MS);
    }

    void on() {
        int i;
        for (i = 0; i < 10; i++)
            call Led.on[i]();
    }

    void off() {
        int i;
        for (i = 0; i < 10; i++)
            call Led.off[i]();
    }

    void wait(uint16_t ms) {
        while(ms--) {
                call BusyWait.wait(1000);
        }
    }

    void longPause() {
        wait(LONG_PAUSE_MS);
    }

    void shortPause() {
        wait(SHORT_PAUSE_MS);
    }

    default command void PanicHook.willPanic(uint16_t panicId) { }
}
