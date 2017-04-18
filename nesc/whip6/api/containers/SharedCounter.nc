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
 *
 * Interface definition for a shared counter of a fixed length that i represented as an
 * array of bytes.
 */
interface SharedCounter {
    /**
     * Returns the current value of the counter as an array of bytes. The first element
     * of the array is the most significant byte. The length of the array may be obtained
     * by calling getLengthBytes(). The returned array cannot be changed, because it backs
     * the counter value. You may manipulate the counter value by calling zero() and
     * increase(). Note that another users of the counter may change its value after you
     * have called this command. However, since all commands are synchronous, the value
     * is always consistent and will not change until you return from the current function.
     */
    command uint8_t *getValue();

    /**
     * Returns the length of the counter in bytes. This value does not change for a
     * particular instance of a counter.
     */
    command uint16_t getLengthBytes();

    /**
     * Sets the current value of the counter to zero.
     */
    command void zero();

    /**
     * Increments the current value of the counter by one.
     */
    command void increment();

    /**
     * Signals that incrementing the counter has caused an overflow.
     */
    event void overflow();
}
