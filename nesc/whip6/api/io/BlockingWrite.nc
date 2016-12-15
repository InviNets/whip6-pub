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

interface BlockingWrite<val_t> {
    /**
     * Writes a value. May return immediately if buffer space is available,
     * but it would block if not.
     *
     * Does not wait for the actual transmission to occur.
     */
    async command error_t write(val_t value);

    /**
     * Blocks until all the written data has been actually sent.
     */
    async command error_t waitForEndOfTransmission();
}
