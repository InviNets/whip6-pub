/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


module ButtonsTestPrv {
    uses interface Boot;
    uses interface Led;
    uses interface ButtonPress[uint8_t nr];
}

implementation {
    event void Boot.booted() {
        uint16_t i;
        for (i = 0; i < 256; i++) {
            call ButtonPress.enable[i]();
        }
        printf("[ButtonsTestPrv] Booted. Press a button!\r\n");
    }

    event void ButtonPress.buttonPressed[uint8_t i]() {
        printf("[ButtonsTestPrv] Pressed button %d\r\n", (int)i);
        call Led.toggle();
    }

    event void ButtonPress.buttonReleased[uint8_t i]() {
        printf("[ButtonsTestPrv] Released button %d\r\n", (int)i);
    }

    default command void ButtonPress.enable[uint8_t i]() { }
}
