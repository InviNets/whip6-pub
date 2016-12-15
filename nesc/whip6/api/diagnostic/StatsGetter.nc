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
 * A getter for a statistic.
 *
 * @param stat_type_t The type of the statistic.
 *
 * @author Konrad Iwanicki
 */
interface StatsGetter<stat_type_t>
{
    /**
     * Returns the current value of the statistic.
     * @return The current value of the statistic.
     */
    command stat_type_t get();
}

