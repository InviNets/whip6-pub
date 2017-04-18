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
 * can be changed at run time.
 *
 * @param conf_val_t The type of a config value.
 * @param def_value The default value.
 *
 * @author Konrad Iwanicki
 */
generic module GenericSettableConfigValueProviderPub(
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
    conf_val_t   m_value = def_value;

    command inline conf_val_t ConfigValue.get()
    {
        return m_value;
    }

    // TODO iwanicki 2013-09-23:
    // Think about a setter interface.
}
