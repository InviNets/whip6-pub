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
#include <external/ucExternalBaseAllocators.h>


/**
 * A platform-independent allocator for IOV elements.
 *
 * @author Konrad Iwanicki
 */
module IOVAllocatorPub
{
    provides
    {
        interface Init @exactlyonce();
    }
    uses
    {
        interface Init as PlatformSpecificInit @atmostonce();
        interface IOVAllocator as PlatformSpecificAllocator @atmostonce();
    }
}
implementation
{
    command inline error_t Init.init()
    {
        return call PlatformSpecificInit.init();
    }



    default command inline error_t PlatformSpecificInit.init()
    {
        return SUCCESS;
    }



    default command inline whip6_iov_blist_t * PlatformSpecificAllocator.allocIOVElement(
            size_t maxSize
    )
    {
        return NULL;
    }



    default command inline void PlatformSpecificAllocator.freeIOVElement(
            whip6_iov_blist_t * iovElem
    )
    {
        // Do nothing.
    }



    whip6_iov_blist_t * whip6_baseAllocNewIoVecChunk(
            size_t maxSize
    ) @C() @spontaneous() // __attribute__((banked))
    {
        return call PlatformSpecificAllocator.allocIOVElement(maxSize);
    }



    void whip6_baseFreeExistingIoVecChunk(
            whip6_iov_blist_t * chunkPtr
    ) @C() @spontaneous() // __attribute__((banked))
    {
        call PlatformSpecificAllocator.freeIOVElement(chunkPtr);
    }
}
