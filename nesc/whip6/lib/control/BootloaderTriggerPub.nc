/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

module BootloaderTriggerPub {
    uses interface BootloaderTrigger;
    uses interface Bootloader;
}
implementation {
    event void BootloaderTrigger.bootloaderRequested() {
        call Bootloader.enterBootloader();
    }
}
