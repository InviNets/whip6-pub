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
 * @author Szymon Acedanski
 */

configuration PlatformSleepStatsPub {
    provides interface AsyncCounter<T32khz, uint32_t> as StatsCounter;
    uses interface StatsIncrementer<uint32_t> as IdleSleepTime;
    uses interface StatsIncrementer<uint32_t> as DeepSleepTime;
}

implementation {
    components HalCC26xxSleepPub;
    components HalCC26xxRTCPub;
    StatsCounter = HalCC26xxRTCPub;
    IdleSleepTime = HalCC26xxSleepPub.IdleSleepTime;
    DeepSleepTime = HalCC26xxSleepPub.DeepSleepTime;
    HalCC26xxSleepPub.StatsCounter -> HalCC26xxRTCPub;
}
