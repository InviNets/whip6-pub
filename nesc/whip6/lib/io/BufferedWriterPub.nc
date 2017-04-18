/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 *
 * This component converts byte-wise asynchronous output into a buffered
 * synchronous output.
 */

#include "Assert.h"

generic module BufferedWriterPub() {
    uses interface AsyncWrite<uint8_t>;
    provides interface BufferedWrite;
}
implementation {
    uint8_t_xdata *tBuf;
    uint16_t tSize, tPos;

    task void writeDone() {
        uint8_t_xdata *b;
        uint16_t sz;

        atomic {
            b = tBuf;
            sz = tSize;
            tBuf = NULL;
        }

        signal BufferedWrite.writeDone(SUCCESS, b, sz);
    }

    command error_t BufferedWrite.startWrite(uint8_t_xdata *buffer, uint16_t size) {
        if(size == 0 || buffer == NULL)
            return EINVAL;

        atomic {
            if(tBuf == NULL) {
                tBuf = buffer;
                tSize = size;
                tPos = 0;
                CHECK(SUCCESS == call AsyncWrite.startWrite(tBuf[tPos++]));
                return SUCCESS;
            }
            else
                return ERETRY;
        }
    }

    async event void AsyncWrite.writeDone(error_t result) {
        CHECK(SUCCESS == result);
        
        atomic {
            if(tPos < tSize) {
                CHECK(SUCCESS == call AsyncWrite.startWrite(tBuf[tPos++]));
            } else {
                post writeDone();
            }
        }
    }
}
