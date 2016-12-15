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
 * A generic fixed-size chunk pool.
 *
 * @param chunk_size The size in bytes of
 *   a single chunk. Must be positive.
 * @param num_chunks The number of chunks in
 *   the pool. Must be positive.
 *
 * @author Konrad Iwanicki
 */
generic module GenericFixedSizeChunkPoolPub(
    size_t chunk_size,
    size_t num_chunks
)
{
    provides
    {
        interface Init @exactlyonce();
        interface ChunkAllocator;
    }
    uses
    {
        interface StatsIncrementer<uint8_t> as NumSuccessfulAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedAllocsStat;
        interface StatsIncrementer<uint8_t> as NumDisposalsStat;
    }
}
implementation
{
    enum
    {
        CHUNK_SIZE = chunk_size,
        NUM_CHUNKS = num_chunks,
        
    };

    typedef struct chunk_content_s
    {
        uint8_t data[CHUNK_SIZE];
    } chunk_content_t;

    struct chunk_s;
    typedef struct chunk_s chunk_t;
    typedef chunk_t chunk_t_xdata; typedef chunk_t_xdata whip6_chunk_t;
    struct chunk_s
    {
        union
        {
            whip6_chunk_t *   pnext;
            chunk_content_t   content;
        } cv;
    };


    whip6_chunk_t     m_chunkPool[NUM_CHUNKS];
    whip6_chunk_t *   m_chunkFree = NULL;

// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

    command error_t Init.init()
    {
        whip6_chunk_t *   chunkPtr;
        size_t            i;

        local_dbg("[Allocator] Initializing allocator %lu.\n\r",
            (long unsigned)(&(m_chunkFree)));

        chunkPtr = &(m_chunkPool[0]);
        m_chunkFree = NULL;
        for (i = NUM_CHUNKS; i > 0; --i)
        {
            chunkPtr->cv.pnext = m_chunkFree;
            m_chunkFree = chunkPtr;
            ++chunkPtr;
        }
        return SUCCESS;
    }



    command inline size_t ChunkAllocator.getChunkSize()
    {
        return CHUNK_SIZE;
    }



    command uint8_t_xdata * ChunkAllocator.allocateChunk()
    {
        whip6_chunk_t *   chunkPtr;
        chunkPtr = m_chunkFree;
        if (chunkPtr == NULL)
        {
#ifdef QUEUE_OR_POOL_PRINTF_IF_FULL
            printf("[ChunkAllocator] Full - returns NULL\n");
#endif  // QUEUE_OR_POOL_PRINTF_IF_FULL
            local_dbg("[Allocator] Unable to allocate a chunk from "
                "allocator %lu.\n\r", (long unsigned)(&(m_chunkFree)));
            call NumFailedAllocsStat.increment(1);
            return NULL;
        }
        m_chunkFree = chunkPtr->cv.pnext;
        local_dbg("[Allocator] Allocated chunk %lu from allocator %lu.\n\r",
            (long unsigned)chunkPtr, (long unsigned)(&(m_chunkFree)));
        call NumSuccessfulAllocsStat.increment(1);
        return &(chunkPtr->cv.content.data[0]);
    }



    command void ChunkAllocator.freeChunk(uint8_t_xdata * rawChunkPtr)
    {
        local_dbg("[Allocator] Freeing chunk %lu to allocator %lu.\n\r",
            (long unsigned)rawChunkPtr, (long unsigned)(&(m_chunkFree)));
        ((whip6_chunk_t *)rawChunkPtr)->cv.pnext = m_chunkFree;
        m_chunkFree = (whip6_chunk_t *)rawChunkPtr;
        call NumDisposalsStat.increment(1);
    }



    default command inline void NumSuccessfulAllocsStat.increment(
            uint8_t val
    )
    {
    }



    default command inline void NumFailedAllocsStat.increment(
            uint8_t val
    )
    {
    }



    default command inline void NumDisposalsStat.increment(
            uint8_t val
    )
    {
    }

#undef local_dbg
}

