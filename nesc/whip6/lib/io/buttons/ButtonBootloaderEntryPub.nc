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
