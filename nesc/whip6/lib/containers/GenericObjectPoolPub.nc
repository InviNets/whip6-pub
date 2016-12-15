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
 * A generic pool of objects of a given type.
 *
 * @param object_type_t The type of the objects.
 * @param num_objs The number of objects in
 *   the pool. Must be positive.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericObjectPoolPub(
    typedef object_type_t,
    size_t num_objs
)
{
    provides
    {
        interface Init @exactlyonce();
        interface ObjectAllocator<object_type_t>;
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
    components new GenericFixedSizeChunkPoolPub(
        sizeof(object_type_t),
        num_objs
    ) as ChunkPoolPrv;
    components new GenericChunkPoolToObjectPoolAdapterPrv(
        object_type_t
    ) as AdapterPrv;

    Init = ChunkPoolPrv;
    ObjectAllocator = AdapterPrv;
    AdapterPrv.ChunkAllocator -> ChunkPoolPrv;
    ChunkPoolPrv.NumSuccessfulAllocsStat = NumSuccessfulAllocsStat;
    ChunkPoolPrv.NumFailedAllocsStat = NumFailedAllocsStat;
    ChunkPoolPrv.NumDisposalsStat = NumDisposalsStat;
}

