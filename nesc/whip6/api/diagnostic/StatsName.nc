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
 * A name provider for a statistic.
 *
 * @author Konrad Iwanicki
 */
interface StatsName
{
    /**
     * Returns the name of the statistic.
     * @return The name of the statistic or NULL.
     */
    command char const * name();

    /**
     * Returns a unique identifier associated
     * with the statistic.
     * @return A unique identifier naming the
     *   statistic.
     */
    command uint16_t id();
}

