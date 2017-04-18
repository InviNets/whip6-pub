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

generic module BufferedWriteToAsyncWriteAdapterPub() {
    uses interface BufferedWrite;
    provides interface AsyncWrite<uint8_t>;
}

implementation {
    bool busy = FALSE;
    uint8_t_xdata byte;

    task void taskPerformWrite() {
        error_t error;
        error = call BufferedWrite.startWrite(&byte, sizeof(byte));
        if(error != SUCCESS) {
            // TODO
        }
    }

    async command error_t AsyncWrite.startWrite(uint8_t value) {
        atomic {
            if(busy) {
                return EBUSY;
            }
            byte = value;
        }

        post taskPerformWrite();
        return SUCCESS;
    }
 
    event void BufferedWrite.writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size) {
        atomic busy = FALSE;
        signal AsyncWrite.writeDone(result);
    }

    default async event void AsyncWrite.writeDone(error_t result) {}
}
