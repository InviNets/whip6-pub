/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_BASE_IO_VEC_ALLOCATION_H__
#define __WHIP6_MICROC_BASE_IO_VEC_ALLOCATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the functionality for
 * allocating I/O vectors.
 *
 */

#include <base/ucIoVec.h>



/**
 * Allocates a chain of I/O vector elements.
 * @param length The total length of the I/O vector.
 * @param lastElemPtrOrNull A pointer to a buffer that
 *   will receive a pointer to the last element of the
 *   allocated I/O vector chain or NULL.
 * @return A pointer to the first element of the allocated
 *   I/O vector chain or NULL meaning that there was
 *   not enough memory to allocate the chain.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX iov_blist_t MCS51_STORED_IN_RAM * whip6_iovAllocateChain(
        size_t length,
        iov_blist_t MCS51_STORED_IN_RAM * * lastElemPtrOrNull
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Frees a chain of I/O vector elements.
 * @param firstElemOrNull A pointer to the first element.
 *   Can be NULL (an empty chain), in which case no
 *   deallocation is necessary
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_iovFreeChain(
        iov_blist_t MCS51_STORED_IN_RAM * firstElemOrNull
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;



#endif /* __WHIP6_MICROC_BASE_IO_VEC_ALLOCATION_H__ */
