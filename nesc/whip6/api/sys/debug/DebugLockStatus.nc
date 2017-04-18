/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


interface DebugLockStatus
{
    /**
     * Checks whether all debugging (except Chip Erase) is locked
     * in hardware, so that the code is protected from being read
     * or tampered externally.
     *
     * This should be true on all production boards.
     *
     * This does not mean that re-programming via our own bootloader
     * is disabled. It should never be.
     */
    command bool isDebuggingLocked();
}
