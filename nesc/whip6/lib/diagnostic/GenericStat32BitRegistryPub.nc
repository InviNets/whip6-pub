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
 * A generic register of 32-bit statistics.
 *
 * @param num_stats The number of statistics.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericStat32BitRegistryPub(
        uint16_t num_stats
)
{
    provides
    {
        interface Init;
        interface StatsRegistry;
        interface StatsPrinter[uint16_t];
        interface StatsName[uint16_t];
        interface StatsGetter<uint32_t>[uint16_t];
        interface StatsSetter<uint32_t>[uint16_t];
        interface StatsIncrementer<uint8_t> as StatsIncrementer8[uint16_t];
        interface StatsIncrementer<uint16_t> as StatsIncrementer16[uint16_t];
        interface StatsIncrementer<uint32_t> as StatsIncrementer32[uint16_t];
    }
    uses
    {
        interface StatsName as SubStatsName[uint16_t];
        interface StatsGetter<uint32_t> as SubStatsGetter[uint16_t];
        interface StatsSetter<uint32_t> as SubStatsSetter[uint16_t];
        interface StatsIncrementer<uint8_t> as SubStatsIncrementer8[uint16_t];
        interface StatsIncrementer<uint16_t> as SubStatsIncrementer16[uint16_t];
        interface StatsIncrementer<uint32_t> as SubStatsIncrementer32[uint16_t];
        interface CommonFormattedTextPrinter;
    }
}
implementation
{
    enum
    {
        NUM_STATS = num_stats,
    };

    components new GenericStat32BitRegistryPrv(NUM_STATS) as GluePrv;

    Init = GluePrv;
    StatsRegistry = GluePrv;
    StatsPrinter = GluePrv;
    StatsName = SubStatsName;
    StatsGetter = SubStatsGetter;
    StatsSetter = SubStatsSetter;
    StatsIncrementer8 = SubStatsIncrementer8;
    StatsIncrementer16 = SubStatsIncrementer16;
    StatsIncrementer32 = SubStatsIncrementer32;
 
    GluePrv.StatsName = SubStatsName;
    GluePrv.StatsGetter = SubStatsGetter;
    GluePrv.StatsSetter = SubStatsSetter;
    GluePrv.CommonFormattedTextPrinter = CommonFormattedTextPrinter;
}
