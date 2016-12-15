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
 * A registry for statistics.
 *
 * @author Konrad Iwanicki
 */
interface StatsRegistry
{
    /**
     * Returns the number of the statistics
     * in the registry.
     * @return The number of statistics.
     */
    command uint16_t getNumStats();

    /**
     * Resets all statistics in the registry to
     * default values.
     */
    command void resetAll();

    /**
     * Prints all statistics in the registry.
     * @param separator The separator between
     *   subsequent statistics or NULL for the
     *   default separator.
     */
    command void printAll(char const * separator);
}

