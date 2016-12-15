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

