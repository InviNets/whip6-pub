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



WHIP6_MICROC_EXTERN_DEF_PREFIX int8_t whip6_iovCompare(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList1,
        iov_blist_t MCS51_STORED_IN_RAM const * iovList2,
        size_t iovOffset1,
        size_t iovOffset2,
        size_t iovLength
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    size_t   numBytesLeft;

    // Locate the place in the first I/O vector from which to read.
    while (iovList1 != NULL)
    {
        if (iovOffset1 < iovList1->iov.len)
        {
            break;
        }
        iovOffset1 -= iovList1->iov.len;
        iovList1 = iovList1->next;
    }
    // Locate the place in the second I/O vector from which to read.
    while (iovList2 != NULL)
    {
        if (iovOffset2 < iovList2->iov.len)
        {
            break;
        }
        iovOffset2 -= iovList2->iov.len;
        iovList2 = iovList2->next;
    }
    numBytesLeft = iovLength;
    while (iovList1 != NULL && iovList2 != NULL && numBytesLeft > 0)
    {
        int8_t MCS51_STORED_IN_RAM const *   ptr1;
        int8_t MCS51_STORED_IN_RAM const *   ptr2;
        size_t                               leftIn1;
        size_t                               leftIn2;
        size_t                               minLeft;

        ptr1 = (int8_t MCS51_STORED_IN_RAM const *)iovList1->iov.ptr + iovOffset1;
        ptr2 = (int8_t MCS51_STORED_IN_RAM const *)iovList2->iov.ptr + iovOffset2;
        leftIn1 = iovList1->iov.len - iovOffset1;
        leftIn2 = iovList2->iov.len - iovOffset2;
        minLeft = leftIn1 < leftIn2 ? leftIn1 : leftIn2;
        if (numBytesLeft < minLeft)
        {
            minLeft = numBytesLeft;
        }
        iovOffset1 += minLeft;
        iovOffset2 += minLeft;
        numBytesLeft -= minLeft;
        if (leftIn1 == minLeft)
        {
            iovList1 = iovList1->next;
            iovOffset1 = 0;
        }
        if (leftIn2 == minLeft)
        {
            iovList2 = iovList2->next;
            iovOffset2 = 0;
        }
        do
        {
            int8_t res = (*ptr1) - (*ptr2);
            if (res != 0)
            {
                return res;
            }
            ++ptr1;
            ++ptr2;
            --minLeft;
        }
        while (minLeft > 0);
    }
    if (numBytesLeft == 0)
    {
        return 0;
    }
    else if (iovList1 == NULL)
    {
        return iovList2 == NULL ? 0 : -1;
    }
    else // if (iovList2 == NULL)
    {
        return 1;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX size_t whip6_iovIteratorCopyBytesAndMoveForward(
        iov_blist_iter_t * srcIovIter,
        iov_blist_iter_t * dstIovIter,
        size_t maxLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   srcIovList;
    iov_blist_t MCS51_STORED_IN_RAM *   dstIovList;
    size_t                              srcIovOffset;
    size_t                              dstIovOffset;
    size_t                              res;

    srcIovList = srcIovIter->currElem;
    srcIovOffset = srcIovIter->offset;
    dstIovList = dstIovIter->currElem;
    dstIovOffset = dstIovIter->offset;
    res = 0;
    while (srcIovList != NULL && dstIovList != NULL && maxLen > 0)
    {
        size_t   srcLen, dstLen, minLen;

        srcLen = srcIovList->iov.len - srcIovOffset;
        dstLen = dstIovList->iov.len - dstIovOffset;
        minLen = srcLen > dstLen ? dstLen : srcLen;
        if (minLen > maxLen)
        {
            minLen = maxLen;
        }
        whip6_longMemCpy(
                srcIovList->iov.ptr + srcIovOffset,
                dstIovList->iov.ptr + dstIovOffset,
                minLen
        );
        if (minLen == srcLen)
        {
            srcIovList = srcIovList->next;
            srcIovOffset = 0;
        }
        else
        {
            srcIovOffset += minLen;
        }
        if (minLen == dstLen)
        {
            dstIovList = dstIovList->next;
            dstIovOffset = 0;
        }
        else
        {
            dstIovOffset += minLen;
        }
        maxLen -= minLen;
        res += minLen;
    }
    srcIovIter->currElem = srcIovList;
    srcIovIter->offset = srcIovOffset;
    dstIovIter->currElem = dstIovList;
    dstIovIter->offset = dstIovOffset;
    return res;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX size_t whip6_iovIteratorSerializeUInt16AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint16_t w
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              iovOffset;
    size_t                              iovLen;

    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 2;
    }
    iovOffset = iovIter->offset;
    iovLen = iovList->iov.len;
    if (iovLen >= iovOffset + 2)
    {
        iovList->iov.ptr[iovOffset] = (uint8_t)(w >> 8);
        ++iovOffset;
    }
    else
    {
        iovList->iov.ptr[iovOffset] = (uint8_t)(w >> 8);
        iovOffset = 0;
        iovList = iovList->next;
        if (iovList == NULL)
        {
            return 1;
        }
        iovLen = iovList->iov.len;
    }
    iovList->iov.ptr[iovOffset] = (uint8_t)(w);
    ++iovOffset;
    if (iovOffset >= iovLen)
    {
        iovOffset = 0;
        iovList = iovList->next;
    }
    iovIter->currElem = iovList;
    iovIter->offset = iovOffset;
    return 0;
}
