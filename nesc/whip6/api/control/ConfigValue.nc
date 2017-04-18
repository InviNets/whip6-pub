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
