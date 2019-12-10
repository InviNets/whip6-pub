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

generic module SingleChunkAllocatorPub(int size) {
    provides interface ChunkAllocator;
}
implementation {
    uint8_t_xdata buf[size] __attribute__((aligned(4)));
    bool isAllocated;

    command size_t ChunkAllocator.getChunkSize() {
        return size;
    }

    command uint8_t_xdata* ChunkAllocator.allocateChunk() {
        if (isAllocated) {
            return NULL;
        }
        isAllocated = TRUE;
        return buf;
    }

    command void ChunkAllocator.freeChunk(uint8_t_xdata * chunk) {
        if (!isAllocated) {
            panic();
        }
        if (chunk != buf) {
            panic();
        }
        isAllocated = FALSE;
    }
}
