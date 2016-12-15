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
 * An adapter that transforms a generic pool of
 * fixed-size chunks into a pool of objects of
 * a given type.
 *
 * @param object_type_t The type of the objects.
 *
 * @author Konrad Iwanicki
 */
generic module GenericChunkPoolToObjectPoolAdapterPrv(
    typedef object_type_t
)
{
    provides interface ObjectAllocator<object_type_t>;
    uses interface ChunkAllocator;
}
implementation
{
    command inline object_type_t * ObjectAllocator.allocate()
    {
        return (object_type_t *)(call ChunkAllocator.allocateChunk());
    }

    command inline void ObjectAllocator.free(object_type_t * object)
    {
        call ChunkAllocator.freeChunk((uint8_t_xdata *)object);
    }
}

