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
 * A generic provider of a config value that
 * cannot be changed at run time.
 *
 * @param conf_val_t The type of the value.
 * @param def_value The value.
 *
 * @author Konrad Iwanicki
 */
generic module GenericConstantConfigValueProviderPub(
        typedef conf_val_t @integer(),
        uint32_t def_value
)
{
    provides
    {
        interface ConfigValue<conf_val_t>;
    }
}
implementation
{
    command inline conf_val_t ConfigValue.get()
    {
        return (conf_val_t)def_value;
    }
}
