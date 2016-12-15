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
 * Logs recorded states to USB in binary form.
 *
 * @author Przemyslaw Horban
 */

#include "StateLogger.h"

generic module StateLoggerToUSBPub(uint8_t bufferSize) {
    provides interface StateLogger;
}
implementation {
    uint8_t buffer[bufferSize];
    uint16_t pos = 0;

    void checkPos() {
        if (pos + 4 >= bufferSize) {
            usb_putchar(STATE_LOG_BUFFER_OVERFLOW);
            usb_putchar(STATE_LOG_ENTRY_SEPARATOR);
            call StateLogger.writeEntry();
        }
    }

    command void StateLogger.log8(uint8_t data) {
        buffer[pos] = data;
        pos += 1;
        checkPos();
    }

    command void StateLogger.log16(uint16_t data) {
        *((uint16_t_xdata*)&buffer[pos]) = data;
        pos += 2;
        checkPos();
    }

    command void StateLogger.log32(uint32_t data) {
        *((uint32_t_xdata*)&buffer[pos]) = data;
        pos += 4;
        checkPos();
    }

    command void StateLogger.writeEntry() {
        uint16_t i;
        for (i = 0; i < pos; i++) {
            usb_putchar(buffer[i]);
        }
        usb_putchar(STATE_LOG_ENTRY_SEPARATOR);
        pos = 0;
    }
}

