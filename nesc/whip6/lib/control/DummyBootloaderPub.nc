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

module DummyBootloaderPub {
    provides interface Bootloader;
    provides interface BlockStorageBootloader;
}

implementation {
    command error_t Bootloader.enterBootloader() {
        return ENOSYS;
    }

    command error_t BlockStorageBootloader.programBlockStorageImage(
            uint32_t offset, uint32_t len) {
        return ENOSYS;
    }
}
