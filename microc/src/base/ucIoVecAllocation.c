/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVecAllocation.h>
#include <external/ucExternalBaseAllocators.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX iov_blist_t MCS51_STORED_IN_RAM * whip6_iovAllocateChain(
        size_t length,
        iov_blist_t MCS51_STORED_IN_RAM * * lastElemPtrOrNull
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   firstElem;
    iov_blist_t MCS51_STORED_IN_RAM *   lastElem;

    firstElem = NULL;
    lastElem = NULL;
    while (length > 0)
    {
        iov_blist_t MCS51_STORED_IN_RAM *   tmpElem;

        tmpElem = whip6_baseAllocNewIoVecChunk(length);
        if (tmpElem == NULL)
        {
            goto FAILURE_ROLLBACK;
        }
        if (lastElem == NULL)
        {
            firstElem = tmpElem;
        }
        else
        {
            lastElem->next = tmpElem;
        }
        tmpElem->prev = lastElem;
        lastElem = tmpElem;
        length -= tmpElem->iov.len;
    }
    if (lastElem != NULL)
    {
        lastElem->next = NULL;
    }
    if (lastElemPtrOrNull != NULL)
    {
        *lastElemPtrOrNull = lastElem;
    }
    return firstElem;

FAILURE_ROLLBACK:
    if (lastElem != NULL)
    {
        lastElem->next = NULL;
        whip6_iovFreeChain(firstElem);
    }
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_iovFreeChain(
        iov_blist_t MCS51_STORED_IN_RAM * currElemOrNull
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM * nextElemOrNull;

    while (currElemOrNull != NULL)
    {
        nextElemOrNull = currElemOrNull->next;
        whip6_baseFreeExistingIoVecChunk(currElemOrNull);
        currElemOrNull = nextElemOrNull;
    }
}
