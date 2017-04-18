/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>



/**
 * An adapter transforming a fixed-size chunk pool
 * into a generic pool of I/O vector chunks
 * of a fixed size.
 *
 * @author Konrad Iwanicki
 */
generic module GenericFixedSizeChunkPoolToIOVElementPoolAdapterPrv()
{
    provides interface IOVAllocator;
    uses interface ChunkAllocator;
}
implementation
{
// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    command whip6_iov_blist_t * IOVAllocator.allocIOVElement(
            size_t maxSize
    )
    {
        whip6_iov_blist_t *   iovElem;
        size_t                chunkLen;

        chunkLen = call ChunkAllocator.getChunkSize();
        if (chunkLen <= sizeof(whip6_iov_blist_t))
        {
            local_dbg("[IOVAllocator] FATAL ERROR.\r\n");
            return NULL;
        }
        chunkLen -= sizeof(whip6_iov_blist_t);
        iovElem = (whip6_iov_blist_t *)call ChunkAllocator.allocateChunk();
        if (iovElem == NULL)
        {
            local_dbg("[IOVAllocator] Out of memory.\r\n");
            return NULL;
        }
        if (chunkLen > maxSize)
        {
            chunkLen = maxSize;
        }
        iovElem->iov.ptr = ((uint8_t_xdata *)iovElem) + sizeof(whip6_iov_blist_t);
        iovElem->iov.len = chunkLen;
        iovElem->next = NULL;
        iovElem->prev = NULL;
        local_dbg("[IOVAllocator] Allocating element %p with buffer %p of length %u.\r\n",
            iovElem, iovElem->iov.ptr, (unsigned)iovElem->iov.len);
        return iovElem;
    }

    command inline void IOVAllocator.freeIOVElement(
            whip6_iov_blist_t * iovElem
    )
    {
        local_dbg("[IOVAllocator] Freeing element %p with buffer %p of length %u.\r\n",
            iovElem, iovElem->iov.ptr, (unsigned)iovElem->iov.len);
        call ChunkAllocator.freeChunk((uint8_t_xdata *)iovElem);
    }

#undef local_dbg
}
