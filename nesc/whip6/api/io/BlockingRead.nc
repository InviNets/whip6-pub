/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface BlockingRead<val_t> {
    /**
     * Reads a value. May return immediately if the value is already in the buffer.
     */
    async command val_t read();

    /**
     * Discards all pending data. May block if the data is being sent and the transmission
     * cannot be stopped right away.
     */
    async command void flushBuffers();
}
