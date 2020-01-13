/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * 
 * This component is responsible for the private details of the boards
 * initialization sequence. In particular, it should be coordinated with
 * board's build.spec to ensure that dependencies of included libraries,
 * like microsc, are met.

 */

#include "InitOrder.h"

configuration CC26xxBasedPub {}
implementation {
    /**
     * Components that do not require run-time initialization:
     */

    // Adds VIMS functions to global namespace.
    components VIMSOverridePub;

    // Adds the interrupt enable bit to global namespace.
    components HalAtomicProviderPub;

    // Provides the _panic() function.
    components PanicPub;
    components HalPanicHookPub;
    PanicPub.PanicHook -> HalPanicHookPub.PanicHook;

    // putchar always available because microc depends on it.
    components PutcharProviderPub;

    // Configure a standard scheduler
    components TinySchedulerPub, MainPub;
    MainPub.Scheduler -> TinySchedulerPub;

    // Configure process scheduler.
    components MainProcessPub;
    TinySchedulerPub.TaskPostedHook -> MainProcessPub.SchedulerTaskPostedHook;
    TinySchedulerPub.McuSleep -> MainProcessPub.SchedulerSleep;

    // Connect the sleep functionality to the scheduler.
    components HalCC26xxSleepPub;
    components IdleProcessPub;
    IdleProcessPub.IdleSleep -> HalCC26xxSleepPub;

    /**
     * Components participating in the booting sequence:
     */

    components BoardStartupPub;

    // Setup context switching.
    BoardStartupPub.InitSequence[INIT_PROCESSES] -> MainProcessPub.Init;
    BoardStartupPub.InitSequence[INIT_PROCESSES] -> IdleProcessPub.Init;

    // Init power domains.
    components HalPowerInitPub;
    BoardStartupPub.InitSequence[INIT_POWER] -> HalPowerInitPub;

    // Init pins.
    components CC26xxPinsPub;
    BoardStartupPub.InitSequence[INIT_PINS] -> CC26xxPinsPub;

    // Setup the sleep timer.
    components HalCC26xxRTCPub;
    BoardStartupPub.InitSequence[INIT_RTC] -> HalCC26xxRTCPub;

    // printf
    components HalPutcharToTFPPrintfAdapterPub;
    BoardStartupPub.InitSequence[0] -> HalPutcharToTFPPrintfAdapterPub;

    // Memory allocators go first.
    components IOVAllocatorPub;
    components Ieee154FrameAllocatorPub;
    components IPv6PacketAllocatorPub;
    BoardStartupPub.InitSequence[0] -> IOVAllocatorPub;
    BoardStartupPub.InitSequence[0] -> Ieee154FrameAllocatorPub;
    BoardStartupPub.InitSequence[0] -> IPv6PacketAllocatorPub;

    // The pseudo-random number generator.
    components PlatformRandomPub;
    BoardStartupPub.InitSequence[0] -> PlatformRandomPub;
}
