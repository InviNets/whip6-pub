/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface AsyncWrite<val_t> {
    /**
     * Begins writing a value. Only one value can be written at a
     * time.
     *
     * @return SUCCESS if value will eventually be written.
     */
    async command error_t startWrite(val_t value);

    /**
     * Reports that a value was written. Next value can be written
     * with startWrite().
     */
    async event void writeDone(error_t result);
}
