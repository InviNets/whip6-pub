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
 * A generic pool of I/O vector chunks
 * of a fixed size.
 *
 * @param chunk_size The size in bytes of
 *   a single chunk. Must be positive.
 * @param num_chunks The number of chunks in
 *   the pool. Must be positive.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericFixedSizeIOVElementPoolPub(
    size_t chunk_size,
    size_t num_chunks
)
{
    provides
    {
        interface Init @exactlyonce();
        interface IOVAllocator;
    }
    uses
    {
        interface StatsIncrementer<uint8_t> as NumSuccessfulIOVElementAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedIOVElementAllocsStat;
        interface StatsIncrementer<uint8_t> as NumIOVElementDisposalsStat;
    }
}
implementation
{
    enum
    {
        CHUNK_SIZE = sizeof(whip6_iov_blist_t) + chunk_size,
        NUM_CHUNKS = num_chunks,
    };

    components new GenericFixedSizeChunkPoolPub(CHUNK_SIZE, NUM_CHUNKS) as ChunkPoolPrv;
    components new GenericFixedSizeChunkPoolToIOVElementPoolAdapterPrv() as AdapterPrv;

    Init = ChunkPoolPrv;
    IOVAllocator = AdapterPrv;

    AdapterPrv.ChunkAllocator -> ChunkPoolPrv;

    ChunkPoolPrv.NumSuccessfulAllocsStat = NumSuccessfulIOVElementAllocsStat;
    ChunkPoolPrv.NumFailedAllocsStat = NumFailedIOVElementAllocsStat;
    ChunkPoolPrv.NumDisposalsStat = NumIOVElementDisposalsStat;
}
