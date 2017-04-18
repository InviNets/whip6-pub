/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic module BlockingWriteBufferedWriterPub() {
    uses interface BlockingWrite<uint8_t>;
    provides interface BufferedWrite;
}
implementation {
    uint8_t_xdata *tBuf;
    uint16_t tSize;

    task void writeTask() {
        error_t err = SUCCESS;
        uint8_t_xdata *buf = tBuf;
        uint16_t i;
        for (i = 0; i < tSize; i++) {
            err = call BlockingWrite.write(buf[i]);
            if (err != SUCCESS) {
                break;
            }
        }

        tBuf = NULL;
        signal BufferedWrite.writeDone(err, buf, tSize);
    }

    command error_t BufferedWrite.startWrite(uint8_t_xdata *buffer, uint16_t size) {
        if(size == 0 || buffer == NULL)
            return EINVAL;

        if(tBuf == NULL) {
            tBuf = buffer;
            tSize = size;
            post writeTask();
            return SUCCESS;
        }
        else
            return ERETRY;
    }
}
