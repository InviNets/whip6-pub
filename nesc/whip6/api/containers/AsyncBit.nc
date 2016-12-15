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
 * A single bit accessable from async code. Note that commands only promise
 * that they were correct at a specific point of time. I.e. isSet() returning
 * TRUE means that bit was set a one point, but may not be set now, after isSet
 * returned. Similarly, assignBoolValue() may have been overwritten. It's your
 * responsibility to use atomic sections where necessary.
 *
 * @author Przemyslaw Horban (extremegf@gmail.com)
 */
interface AsyncBit
{
    /**
     * Checks if this bit is set.
     * @return FALSE if the bit is not set,
     *   or TRUE otherwise.
     */
    async command bool isSet();

    /**
     * Checks if this bit is clear (i.e., not set).
     * @return FALSE if the bit is set,
     *   or TRUE otherwise.
     */
    async command bool isClear();

    /**
     * Sets the bit.
     */
    async command void set();

    /**
     * Clears the bit.
     */
    async command void clear();

    /**
     * Sets the value of a bit to a given boolean
     * value, that is, clears the bit if the
     * given value is FALSE or sets it otherwise.
     * @param val The value to be set.
     */
    async command void assignBoolValue(bool val);

    /**
     * Note:
     *
     * Toggle is not available, because it would always require the use of
     * atomic {} internally.  Programmer should decide about it on case-by-case
     * basis
     *
     * async command void toggleValue();
     */
}
