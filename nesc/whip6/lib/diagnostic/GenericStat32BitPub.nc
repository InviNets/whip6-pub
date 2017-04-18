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
 * A generic implementation of a 32-bit statistic.
 *
 * @param stat_id The identifier of the statistic.
 * @param stat_name The name of the statistic or NULL.
 * @param def_value The default (initial) value of
 *   the statistic.
 *
 * @author Konrad Iwanicki
 */
generic module GenericStat32BitPub(
        uint16_t stat_id,
        char const stat_name[],
        uint32_t def_value
)
{
    provides
    {
        interface StatsName;
        interface StatsGetter<uint32_t>;
        interface StatsSetter<uint32_t>;
        interface StatsIncrementer<uint8_t> as StatsIncrementer8;
        interface StatsIncrementer<uint16_t> as StatsIncrementer16;
        interface StatsIncrementer<uint32_t> as StatsIncrementer32;
    }
}
implementation
{

    uint32_t   m_statValue = def_value;


    command inline char const * StatsName.name()
    {
        return stat_name;
    }

    command inline uint16_t StatsName.id()
    {
        return stat_id;
    }

    command inline uint32_t StatsGetter.get()
    {
        return m_statValue;
    }

    command inline void StatsSetter.setToDefault()
    {
        call StatsSetter.setToValue(def_value);
    }
    
    command inline void StatsSetter.setToValue(uint32_t val)
    {
        m_statValue = val;
    }

    command inline void StatsIncrementer8.increment(uint8_t dval)
    {
        m_statValue += dval;
    }

    command inline void StatsIncrementer16.increment(uint16_t dval)
    {
        m_statValue += dval;
    }

    command inline void StatsIncrementer32.increment(uint32_t dval)
    {
        m_statValue += dval;
    }

}
