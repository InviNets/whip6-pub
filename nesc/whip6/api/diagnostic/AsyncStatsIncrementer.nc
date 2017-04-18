/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * An incrementer for a statistic. An async version of
 * StatsIncrementer.
 *
 * @author Szymon Acedanski
 */
interface AsyncStatsIncrementer<increment_type_t>
{
    /**
     * Increments a statistic by a given value.
     * @param val The value by which the statistic
     *   is to be incremented.
     */
    async command void increment(increment_type_t val);
}
