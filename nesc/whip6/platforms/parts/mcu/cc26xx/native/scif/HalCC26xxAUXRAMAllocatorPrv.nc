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
 * @author Szymon Acedanski
 */

#include <inc/hw_memmap.h>

module HalCC26xxAUXRAMAllocatorPrv {
    provides interface ChunkAllocator;
    uses interface AskBeforeSleep;
}
implementation {
    bool isAllocated;

    command size_t ChunkAllocator.getChunkSize() {
        return 2048;
    }

    command uint8_t_xdata* ChunkAllocator.allocateChunk() {
        if (isAllocated) {
            return NULL;
        }
        isAllocated = TRUE;
        return (uint8_t_xdata*)AUX_RAM_BASE;
    }

    command void ChunkAllocator.freeChunk(uint8_t_xdata * chunk) {
        if (!isAllocated) {
            panic();
        }
        if (chunk != (uint8_t_xdata*)AUX_RAM_BASE) {
            panic();
        }
        isAllocated = FALSE;
    }

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        // TODO: in the future we may consider enabling retention (or maybe even
        //       it's enabled by default, I didn't check) after ensuring that
        //       everything is correctly configured and sleep does not use
        //       excessive energy.
        return isAllocated ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }
}
