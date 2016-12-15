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
 * A global register of 32-bit statistics.
 *
 * @param num_stats The number of statistics.
 *
 * @author Konrad Iwanicki
 */
configuration GlobalStat32BitRegistryPub
{
    provides
    {
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
        NUM_STATS = uniqueCount("GlobalStat32BitRegistryPub"),
    };

    components new GenericStat32BitRegistryPub(NUM_STATS) as ImplPrv;
    components BoardStartupPub;

    BoardStartupPub.InitSequence[0] -> ImplPrv;
    StatsRegistry = ImplPrv;
    StatsPrinter = ImplPrv;
    StatsName = ImplPrv;
    StatsGetter = ImplPrv;
    StatsSetter = ImplPrv;
    StatsIncrementer8 = ImplPrv;
    StatsIncrementer16 = ImplPrv;
    StatsIncrementer32 = ImplPrv;
 
    ImplPrv.SubStatsName = SubStatsName;
    ImplPrv.SubStatsGetter = SubStatsGetter;
    ImplPrv.SubStatsSetter = SubStatsSetter;
    ImplPrv.SubStatsIncrementer8 = SubStatsIncrementer8;
    ImplPrv.SubStatsIncrementer16 = SubStatsIncrementer16;
    ImplPrv.SubStatsIncrementer32 = SubStatsIncrementer32;
    ImplPrv.CommonFormattedTextPrinter = CommonFormattedTextPrinter;
}

