/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

generic module BufferedReadToReadNowAdapterPub() {
    provides interface ReadNow<uint8_t>;
    uses interface BufferedRead;
}

implementation {
    bool busy = FALSE;
    uint8_t_xdata byte;

    task void taskPerformRead() {
        error_t error;
        call BufferedRead.setActive(TRUE);
        error = call BufferedRead.startRead(&byte, sizeof(byte));
        if(error != SUCCESS) {
            atomic busy = FALSE;
            signal ReadNow.readDone(error, 0);
        }
    }

    async command error_t ReadNow.read() {
        atomic {
            if(busy) {
                return EBUSY;
            }
            busy = TRUE;
        }
        post taskPerformRead();
        return SUCCESS;
    }

    event void BufferedRead.readDone(uint8_t_xdata *buffer, uint16_t capacity) {
        atomic busy = FALSE;
        signal ReadNow.readDone(SUCCESS, byte);
    }

    event void BufferedRead.bytesLost(uint16_t lostCount) {}

    default async event void ReadNow.readDone(error_t result, uint8_t val) {}
}
