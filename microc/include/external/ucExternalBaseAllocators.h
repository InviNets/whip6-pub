/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_EXTERNAL_EXTERNAL_BASE_ALLOCATORS_H__
#define __WHIP6_MICROC_EXTERNAL_EXTERNAL_BASE_ALLOCATORS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains prototypes of allocator functions
 * for base types in microc.
 */

#include <base/ucIoVec.h>


/**
 * Allocates a doubly-linked I/O vector chunk with
 * a given size limitation. The allocated chunk can
 * actually be smaller than the requested one, but
 * its size is always at least 1.
 * @param maxSize The maximal requested size.
 * @return A pointer to a doubly-linked I/O vector
 *   element with an underlying chunk of a size
 *   not greater than the requested one, or NULL
 *   if allocation failed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX iov_blist_t MCS51_STORED_IN_RAM * whip6_baseAllocNewIoVecChunk(
        size_t size
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Frees a doubly-linked I/O vector chunk.
 * @param chunkPtr A pointer to the I/O vector
 *   element to be freed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_baseFreeExistingIoVecChunk(
        iov_blist_t MCS51_STORED_IN_RAM * chunkPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_EXTERNAL_EXTERNAL_BASE_ALLOCATORS_H__ */
