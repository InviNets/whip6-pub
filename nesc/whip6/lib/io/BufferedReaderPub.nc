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
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * 
 * This component reads bytes from the ReadNow interface, when active, and
 * stores them in a buffer provided by the user.
 *
 * If a record cannot be stored for whatever reason, this fact is signaled
 * though bytesLost event.
 *
 * Important note: ReadNow.read() will be called from an atomic section. Make
 * sure that this does not cause a deadlock.
 */

#include "Assert.h"

generic module BufferedReaderPub(int internal_buffer_size) {
    uses interface ReadNow<uint8_t>;
    provides interface BufferedRead;
}
implementation {
    //
    // Internal circular buffer.
    //
    // Invariants:
    //   - head points to the first empty space in the buffer; there always is
    //     at least one empty space
    //   - tail points to the first stored value, if any value is stored,
    //     otherwise tail equals head.
    //
    uint8_t internal_buffer[internal_buffer_size];
    uint8_t internal_buffer_head = 0;  // Index of the first empty space.
    uint8_t internal_buffer_tail = 0;  // Index of the first stored value.

    //
    // External buffer to fill.
    //
    // Invariants:
    //   - if external_buffer is NULL, then pos and size have no meaning
    //   - otherwise, pos points to the first empty space and pos < size
    //   - when the buffer is full, external_buffer is immediately set to NULL
    //   - external_buffer can be read in async code, therefore all writes to it
    //     must be atomic
    //   - external_buffer_* are never touched by async code
    //
    uint8_t_xdata* external_buffer = NULL;
    uint16_t external_buffer_size;
    uint16_t external_buffer_pos;

    bool is_active = FALSE;
    bool is_reading = FALSE;
    uint16_t lost_bytes = 0;

    inline void internal_buffer_inc_pos(uint8_t* pos) {
        *pos = ((*pos) + 1) % internal_buffer_size;
    }

    task void process() {
        uint16_t lost_bytes_copy;
        atomic {
            lost_bytes_copy = lost_bytes;
            lost_bytes = 0;
        }
        if (lost_bytes_copy)
            signal BufferedRead.bytesLost(lost_bytes_copy);

        for (;;) {
            bool internal_buffer_empty;
            uint8_t internal_buffer_value;
            if (external_buffer == NULL)
                break;
            atomic {
                internal_buffer_empty =
                    (internal_buffer_head == internal_buffer_tail);
                internal_buffer_value = internal_buffer[internal_buffer_tail];
                if (!internal_buffer_empty) {
                    internal_buffer_tail = (internal_buffer_tail + 1) % internal_buffer_size; 
                }
            }
            if (internal_buffer_empty)
                break;
            external_buffer[external_buffer_pos++] = internal_buffer_value;
            if (external_buffer_pos == external_buffer_size) {
                uint8_t_xdata* external_buffer_copy = external_buffer;
                atomic external_buffer = NULL;
                signal BufferedRead.readDone(external_buffer_copy,
                    external_buffer_size);
            }
        }
    }

    command void BufferedRead.setActive(bool active) {
        atomic {
            is_active = active;
            if (active && !is_reading) {
                is_reading = TRUE;
                CHECK(call ReadNow.read() == SUCCESS);
            }
        }
    }

    command error_t BufferedRead.startRead(uint8_t_xdata *buf, uint16_t cap) {
        if (buf == NULL || cap == 0)
            return EINVAL;
        if (external_buffer != NULL)
            return EBUSY;
        atomic external_buffer = buf;
        external_buffer_size = cap;
        external_buffer_pos = 0;
        post process();
        return SUCCESS;
    }

    command void BufferedRead.flush() {
        atomic {
            internal_buffer_head = internal_buffer_tail;
            external_buffer = NULL;
        }
    }

    async event void ReadNow.readDone(error_t result, uint8_t val) {
        atomic {
            if (!is_active) {
                is_reading = FALSE;
                return;
            }
            if (result != SUCCESS) {
                lost_bytes++;
            } else {
                internal_buffer[internal_buffer_head] = val;
                internal_buffer_inc_pos(&internal_buffer_head);
                if (internal_buffer_head == internal_buffer_tail) {
                    lost_bytes++;
                    internal_buffer_inc_pos(&internal_buffer_tail);
                }
            }
            if (lost_bytes || external_buffer != NULL)
                post process();
        }

        // XXX(accek): what if this recursively signals the event immediately?
        //             if it's possible, we may try to ensure that the compiler
        //             can optimize this as a tail call (and we should remove
        //             the CHECK() call in this case.
        CHECK(call ReadNow.read() == SUCCESS);
    }
}
