/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * An incrementer for a statistic.
 *
 * @param increment_type_t The type by which the
 *   statistic can be incremented.
 *
 * @author Konrad Iwanicki
 */
interface StatsIncrementer<increment_type_t>
{
    /**
     * Increments a statistic by a given value.
     * @param val The value by which the statistic
     *   is to be incremented.
     */
    command void increment(increment_type_t val);
}
