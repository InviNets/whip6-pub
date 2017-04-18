/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include <driverlib/aon_event.h>

configuration HalCC26xxRTCPub {
    provides interface Init;
    provides interface Timer<T32khz, uint32_t>;
    provides interface TimerOverflow;
    provides interface AsyncCounter<T32khz, uint32_t>;
    provides interface AsyncCounter<T32khz, uint64_t> as AsyncCounter64;
}
implementation {
    components HalCC26xxRTCPrv;
    Init = HalCC26xxRTCPrv;
    Timer = HalCC26xxRTCPrv;
    TimerOverflow = HalCC26xxRTCPrv;
    AsyncCounter = HalCC26xxRTCPrv;
    AsyncCounter64 = HalCC26xxRTCPrv;

    components HplRTCInterruptPub;
    HalCC26xxRTCPrv.RTCInterrupt -> HplRTCInterruptPub;

    components new CC26xxWakeUpSourcePub(AON_EVENT_RTC_CH0);
    HalCC26xxRTCPrv.WakeUpSource -> CC26xxWakeUpSourcePub;

    components new HalAskBeforeSleepPub();
    HalCC26xxRTCPrv.AskBeforeSleep -> HalAskBeforeSleepPub;

}
