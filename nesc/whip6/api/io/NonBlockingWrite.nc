/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 *
 */
interface NonBlockingWrite<val_t> {
    /**
     * Writes a value. Always returns immediately (will add information when some bytes are lost).
     */
    async command error_t write(val_t value);
}
