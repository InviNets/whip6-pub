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
 * A reader of configuration values.
 *
 * @param val_t The type of the value.
 *
 * @author Konrad Iwanicki
 */
interface ConfigValue<val_t>
{
    /**
     * Returns the value.
     * @return The value.
     */
    command val_t get();
}

