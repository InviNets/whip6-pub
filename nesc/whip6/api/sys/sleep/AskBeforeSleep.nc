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
 * @author Przemyslaw Horban
 */

#include <SleepLevels.h>

interface AskBeforeSleep
{
    /**
     * The handler should return the deepest sleep level that the asked
     * component allows.
     * 
     * After this event is triggered and returns (after combining all handlers)
     * SLEEP_LEVEL_IDLE or a deeper state, then the instruction execution will
     * always be halted.  The user must ensure that some interrupt will fire,
     * to wake the MCU up.
     */
    event sleep_level_t maxSleepLevel();
}
