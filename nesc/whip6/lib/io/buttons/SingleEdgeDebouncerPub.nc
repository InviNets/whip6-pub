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

generic module SingleEdgeDebouncerPub(uint16_t nextDetectDelayMs) {
    uses interface ExternalEvent as PressEvent;
    uses interface Timer<TMilli, uint32_t> as EventIgnoreWindow;

    provides interface ButtonPress;
    provides interface Button;
}
implementation {
    bool enabled;
    bool ignoring;

    command void ButtonPress.enable() {
        call EventIgnoreWindow.stop();
        call PressEvent.clearPending();
        call PressEvent.asyncNotifications(TRUE);
        enabled = TRUE;
        ignoring = FALSE;
    }

    command void ButtonPress.disable() {
        enabled = FALSE;
        ignoring = FALSE;
        call EventIgnoreWindow.stop();
        call PressEvent.clearPending();
        call PressEvent.asyncNotifications(FALSE);
    }

    event void EventIgnoreWindow.fired() {
        call EventIgnoreWindow.stop();
        ignoring = FALSE;

        if(enabled) {
            call PressEvent.clearPending();
            call PressEvent.asyncNotifications(TRUE);
            signal ButtonPress.buttonReleased();
        }
    }

    task void pressDetected() {
        if(enabled) {
            signal ButtonPress.buttonPressed();
            call EventIgnoreWindow.startWithTimeoutFromNow(nextDetectDelayMs);
            ignoring = TRUE;
        }
    }

    command bool Button.isPressed() {
        return ignoring;
    }

#ifdef MEMDUMP_ON_ANY_GPIO_INTERRUPT
    uint8_t_xdata *memdump = 0x0;

    void dumpMem() {
        uint16_t line;
        uint8_t column;

        printf("DUMP:\n");
        for (line = 0; line < 1024 * 8 / 16; line++) {
            printf("DLN%04X ", line * 16);
            for (column = 0; column < 16; column++)
                printf("%02X ", memdump[line * 16 + column]);
            printf("\n");
        }
    }
#endif  // MEMDUMP_ON_ANY_GPIO_INTERRUPT

    async event void PressEvent.triggered() {
#ifdef MEMDUMP_ON_ANY_GPIO_INTERRUPT
        // This function serves another purpose. We want to be able to dump
        // memory in a roubust way. Best way is catch GPIO interrupts and
        // dump the memory in the handler, so that is happens even if
        // the node hangs.
        dumpMem();
#endif  // MEMDUMP_ON_ANY_GPIO_INTERRUPT

        post pressDetected();
        call PressEvent.asyncNotifications(FALSE);
    }

    default event void ButtonPress.buttonPressed() {}
    default event void ButtonPress.buttonReleased() {}
}
