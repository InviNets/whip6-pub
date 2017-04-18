/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

generic module ButtonBootloaderEntryPub() {
    provides interface Init @exactlyonce();

    uses interface ButtonPress @exactlyonce();
    uses interface Bootloader @exactlyonce();
}
implementation {
    command error_t Init.init() {
        call ButtonPress.enable();
        return SUCCESS;
    }

    event void ButtonPress.buttonPressed() {
        call Bootloader.enterBootloader();
    }

    event void ButtonPress.buttonReleased() {
        // LOL
    }
}
