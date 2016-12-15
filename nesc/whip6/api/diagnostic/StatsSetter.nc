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
 * A setter for a statistic.
 *
 * @param stat_type_t The type of the statistic.
 *
 * @author Konrad Iwanicki
 */
interface StatsSetter<stat_type_t>
{
    /**
     * Sets the statistic to a default value.
     */
    command void setToDefault();
    
    /**
     * Sets the statistic to a given value.
     * @param val The value.
     */
    command void setToValue(stat_type_t val);
}

