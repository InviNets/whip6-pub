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
 * An allocator for IOV elements.
 *
 * @author Konrad Iwanicki
 */
interface IOVAllocator
{
    /**
     * Allocates a IOV element.
     * @param size The maximal requested size.
     *   The returned IOV element can be shorter.
     * @return A pointer to the allocated IOV element
     *   or NULL if there is no memory to allocate one.
     */
    command whip6_iov_blist_t * allocIOVElement(size_t maxSize);

    /**
     * Frees a previously allocated IOV element.
     * @param iovElem A pointer to the IOV element
     *   to be freed.
     */
    command void freeIOVElement(whip6_iov_blist_t * iovElem);
}
