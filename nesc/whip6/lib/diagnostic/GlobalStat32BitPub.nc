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
 * A 32-bit statistic that is bound to the
 * global register.
 *
 * @param stat_id The identifier of the statistic.
 * @param stat_name The name of the statistic or NULL.
 * @param def_value The default (initial) value of
 *   the statistic.
 *
 * @author Konrad Iwanicki
 */
generic configuration GlobalStat32BitPub(
        uint16_t stat_id,
        char const stat_name[],
        uint32_t def_value
)
{
    provides
    {
        interface StatsName;
        interface StatsPrinter;
        interface StatsGetter<uint32_t>;
        interface StatsSetter<uint32_t>;
        interface StatsIncrementer<uint8_t> as StatsIncrementer8;
        interface StatsIncrementer<uint16_t> as StatsIncrementer16;
        interface StatsIncrementer<uint32_t> as StatsIncrementer32;
    }
}
implementation
{

    enum
    {
        STAT_IDX = unique("GlobalStat32BitRegistryPub"),
    };

    components GlobalStat32BitRegistryPub as RegistryPrv;
    components new GenericStat32BitPub(stat_id, stat_name, def_value) as StatPrv;

    StatsName = StatPrv;
    StatsPrinter = RegistryPrv.StatsPrinter[STAT_IDX];
    StatsGetter = StatPrv;
    StatsSetter = StatPrv;
    StatsIncrementer8 = StatPrv;
    StatsIncrementer16 = StatPrv;
    StatsIncrementer32 = StatPrv;

    RegistryPrv.SubStatsName[STAT_IDX] -> StatPrv;
    RegistryPrv.SubStatsGetter[STAT_IDX] -> StatPrv;
    RegistryPrv.SubStatsSetter[STAT_IDX] -> StatPrv;
    RegistryPrv.SubStatsIncrementer8[STAT_IDX] -> StatPrv;
    RegistryPrv.SubStatsIncrementer16[STAT_IDX] -> StatPrv;
    RegistryPrv.SubStatsIncrementer32[STAT_IDX] -> StatPrv;
}
