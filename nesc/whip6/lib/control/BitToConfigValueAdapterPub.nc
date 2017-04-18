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
 * An adapter from a bit with synchronous interface
 * to a boolean config value.
 *
 * @author Konrad Iwanicki
 */
generic module BitToConfigValueAdapterPub()
{
    provides interface ConfigValue<bool>;
    uses interface Bit as SubBit;
}
implementation
{
    command inline bool ConfigValue.get()
    {
        return call SubBit.isSet();
    }
}
