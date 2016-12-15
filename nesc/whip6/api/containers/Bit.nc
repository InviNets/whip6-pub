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
 * A single bit accessed from synchronous
 * code.
 *
 * @author Konrad Iwanicki
 */
interface Bit
{
    /**
     * Checks if this bit is set.
     * @return FALSE if the bit is not set,
     *   or TRUE otherwise.
     */
    command bool isSet();

    /**
     * Checks if this bit is clear (i.e., not set).
     * @return FALSE if the bit is set,
     *   or TRUE otherwise.
     */
    command bool isClear();

    /**
     * Sets the bit.
     */
    command void set();

    /**
     * Clears the bit.
     */
    command void clear();

    /**
     * Sets the value of a bit to a given boolean
     * value, that is, clears the bit if the
     * given value is FALSE or sets it otherwise.
     * @param val The value to be set.
     */
    command void assignBoolValue(bool val);
    
    /**
     * Changes the value of this bit to
     * an opposite one.
     */
    command void toggleValue();
}

