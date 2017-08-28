/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <DimensionTypes.h>

/**
 * @author Szymon Acedanski
 * 
 * A unit converter for DimensionalRead.
 */

generic module DimensionalReadMuxPub(typedef units_tag,
        typedef val_t @integer(), int numInstances)
{
    uses interface DimensionalRead<units_tag, val_t> as From;
    provides interface DimensionalRead<units_tag, val_t> as To[uint8_t];
}
implementation
{
    typedef enum {
        STATE_IDLE,
        STATE_READING,
        STATE_DELIVERING_READ_DONE
    } state_t;

    state_t state;
    bool isReading[numInstances];

    command inline error_t To.read[uint8_t instance]() {
        error_t err;
        if (isReading[instance] || state == STATE_DELIVERING_READ_DONE) {
            return EBUSY;
        }
        isReading[instance] = TRUE;
        if (state != STATE_IDLE) {
            // Read already in progress, we will use that result.
            return SUCCESS;
        }
        state = STATE_READING;
        err = call From.read();
        if (err != SUCCESS) {
            state = STATE_IDLE;
            isReading[instance] = FALSE;
        }
        return err;
    }

    event inline void From.readDone(error_t result, val_t val) {
        uint8_t i;
        state = STATE_DELIVERING_READ_DONE;
        for (i = 0; i < numInstances; i++) {
            if (isReading[i]) {
                isReading[i] = FALSE;
                signal To.readDone[i](result, val);
            }
        }
        state = STATE_IDLE;
    }

    default event void To.readDone[uint8_t instance](error_t result, val_t val) { }
}
