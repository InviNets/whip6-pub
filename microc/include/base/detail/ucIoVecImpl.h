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

#ifndef __WHIP6_MICROC_BASE_DETAIL_IO_VEC_IMPL_H__
#define __WHIP6_MICROC_BASE_DETAIL_IO_VEC_IMPL_H__

#ifndef __WHIP6_MICROC_BASE_IO_VEC_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_BASE_IO_VEC_H__ */

#include <stdio.h>
#include <base/ucString.h>



WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_iovIteratorInitToArbitrary(
        iov_blist_t MCS51_STORED_IN_RAM * currElem,
        size_t offset,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovGetTotalLength(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    size_t res = 0;
    while (iovList != NULL)
    {
        res += iovList->iov.len;
        iovList = iovList->next;
    }
    return res;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX int8_t whip6_iovShortCompare(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t numBytesLeft;
    // Check if there is anything to compare.
    if (bufPtr == NULL)
    {
        return 0;
    }
    // Locate the place from which to compare.
    while (iovList != NULL)
    {
        if (iovOffset < iovList->iov.len)
        {
            break;
        }
        iovOffset -= iovList->iov.len;
        iovList = iovList->next;
    }
    // Compare.
    numBytesLeft = bufLen;
    while (numBytesLeft > 0 && iovList != NULL)
    {
        size_t    iovSpace = iovList->iov.len - iovOffset;
        uint8_t   tmp = numBytesLeft;
        int8_t    res;
        if ((size_t)tmp > iovSpace) {
            tmp = (uint8_t)iovSpace;
        }
        res = whip6_shortMemCmp(iovList->iov.ptr + iovOffset, bufPtr, tmp);
        if (res != 0)
        {
            return res;
        }
        bufPtr += tmp;
        numBytesLeft -= tmp;
        iovList = iovList->next;
        iovOffset = 0;
    }
    return numBytesLeft == 0 ? (int8_t)0 : (int8_t)-1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_iovShortWrite(
        iov_blist_t MCS51_STORED_IN_RAM * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t numBytesLeft;
    // Check that there is anything to write.
    if (bufPtr == NULL)
    {
        return 0;
    }
    // Locate the place at which to write.
    while (iovList != NULL)
    {
        if (iovOffset < iovList->iov.len)
        {
            break;
        }
        iovOffset -= iovList->iov.len;
        iovList = iovList->next;
    }
    // Write.
    numBytesLeft = bufLen;
    while (numBytesLeft > 0 && iovList != NULL)
    {
        uint8_t   tmp = numBytesLeft;
        size_t    iovSpace = iovList->iov.len - iovOffset;
        if ((size_t)tmp > iovSpace) {
            tmp = (uint8_t)iovSpace;
        }
        whip6_shortMemCpy(bufPtr, iovList->iov.ptr + iovOffset, tmp);
        bufPtr += tmp;
        numBytesLeft -= tmp;
        iovList = iovList->next;
        iovOffset = 0;
    }
    return bufLen - numBytesLeft;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_iovShortRead(
        iov_blist_t MCS51_STORED_IN_RAM const * iovList,
        size_t iovOffset,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t numBytesLeft;
    // Check if there is anything to read.
    if (bufPtr == NULL)
    {
        return 0;
    }
    // Locate the place from which to read.
    while (iovList != NULL)
    {
        if (iovOffset < iovList->iov.len)
        {
            break;
        }
        iovOffset -= iovList->iov.len;
        iovList = iovList->next;
    }
    // Read.
    numBytesLeft = bufLen;
    while (numBytesLeft > 0 && iovList != NULL)
    {
        uint8_t   tmp = numBytesLeft;
        size_t    iovSpace = iovList->iov.len - iovOffset;
        if ((size_t)tmp > iovSpace) {
            tmp = (uint8_t)iovSpace;
        }
        whip6_shortMemCpy(iovList->iov.ptr + iovOffset, bufPtr, tmp);
        bufPtr += tmp;
        numBytesLeft -= tmp;
        iovList = iovList->next;
        iovOffset = 0;
    }
    return bufLen - numBytesLeft;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_iovIteratorInitToBeginning(
        iov_blist_t MCS51_STORED_IN_RAM * iovList,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    iovIter->currElem = iovList;
    iovIter->offset = 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_iovIteratorInitToArbitrary(
        iov_blist_t MCS51_STORED_IN_RAM * currElem,
        size_t offset,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iovIter->currElem = currElem;
    iovIter->offset = offset;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_iovIteratorInvalidate(
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    iovIter->currElem = NULL;
    iovIter->offset = 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_iovIteratorClone(
        iov_blist_iter_t const * srcIovIter,
        iov_blist_iter_t * dstIovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    dstIovIter->currElem = srcIovIter->currElem;
    dstIovIter->offset = srcIovIter->offset;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_iovIteratorIsValid(
        iov_blist_iter_t const * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return iovIter->currElem != NULL;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovIteratorMoveForward(
        iov_blist_iter_t * iovIter,
        size_t offset
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              tmp;
    size_t                              res;

    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 0;
    }
    tmp = iovList->iov.len - iovIter->offset;
    if (tmp > offset)
    {
        iovIter->offset += offset;
        res = offset;
    }
    else
    {
        offset -= tmp;
        res = tmp;
        iovList = iovList->next;
        while (iovList != NULL)
        {
            tmp = iovList->iov.len;
            if (offset < tmp)
            {
                res += offset;
                break;
            }
            offset -= tmp;
            res += tmp;
            iovList = iovList->next;
        }
        iovIter->currElem = iovList;
        iovIter->offset = offset;
    }
    return res;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovIteratorMoveBackward(
        iov_blist_iter_t * iovIter,
        size_t remBytes
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              subBytes;

    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 0;
    }
    subBytes = iovIter->offset;
    if (subBytes >= remBytes)
    {
        subBytes = remBytes;
        iovIter->offset -= subBytes;
    }
    else
    {
        remBytes -= subBytes;
        iovList = iovList->prev;
        while (iovList != NULL)
        {
            size_t tmp = iovList->iov.len;
            if (remBytes <= tmp)
            {
                subBytes += remBytes;
                iovIter->offset = tmp - remBytes;
                break;
            }
            remBytes -= tmp;
            subBytes += tmp;
            iovList = iovList->prev;
        }
        iovIter->currElem = iovList;
    }
    return subBytes;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovIteratorReadAndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              iovOffset;
    size_t                              res;

    if (bufPtr == NULL || bufLen == 0)
    {
        return 0;
    }
    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 0;
    }
    iovOffset = iovIter->offset;
    res = iovList->iov.len - iovOffset;
    if (res > bufLen)
    {
        res = bufLen;
        whip6_longMemCpy(iovList->iov.ptr + iovOffset, bufPtr, res);
        iovIter->offset = iovOffset + res;
    }
    else
    {
        whip6_longMemCpy(iovList->iov.ptr + iovOffset, bufPtr, res);
        bufPtr += res;
        bufLen -= res;
        iovList = iovList->next;
        iovOffset = 0;
        while (iovList != NULL && bufLen > 0)
        {
            iovOffset = iovList->iov.len;
            if (iovOffset > bufLen)
            {
                iovOffset = bufLen;
                whip6_longMemCpy(iovList->iov.ptr, bufPtr, iovOffset);
                res += iovOffset;
                break;
            }
            else
            {
                whip6_longMemCpy(iovList->iov.ptr, bufPtr, iovOffset);
                res += iovOffset;
                bufPtr += iovOffset;
                bufLen -= iovOffset;
                iovList = iovList->next;
                iovOffset = 0;
            }
        }
        iovIter->currElem = iovList;
        iovIter->offset = iovOffset;
    }
    return res;
}



WHIP6_MICROC_PRIVATE_DECL_PREFIX size_t whip6_iovIteratorWriteAndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              iovOffset;
    size_t                              res;

    if (bufPtr == NULL || bufLen == 0)
    {
        return 0;
    }
    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 0;
    }
    iovOffset = iovIter->offset;
    res = iovList->iov.len - iovOffset;
    if (res > bufLen)
    {
        res = bufLen;
        whip6_longMemCpy(bufPtr, iovList->iov.ptr + iovOffset, res);
        iovIter->offset = iovOffset + res;
    }
    else
    {
        whip6_longMemCpy(bufPtr, iovList->iov.ptr + iovOffset, res);
        bufPtr += res;
        bufLen -= res;
        iovList = iovList->next;
        iovOffset = 0;
        while (iovList != NULL && bufLen > 0)
        {
            iovOffset = iovList->iov.len;
            if (iovOffset > bufLen)
            {
                iovOffset = bufLen;
                whip6_longMemCpy(bufPtr, iovList->iov.ptr, iovOffset);
                res += iovOffset;
                break;
            }
            else
            {
                whip6_longMemCpy(bufPtr, iovList->iov.ptr, iovOffset);
                res += iovOffset;
                bufPtr += iovOffset;
                bufLen -= iovOffset;
                iovList = iovList->next;
                iovOffset = 0;
            }
        }
        iovIter->currElem = iovList;
        iovIter->offset = iovOffset;
    }
    return res;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovIteratorSerializeUInt8AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint8_t b
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              iovOffset;

    iovList = iovIter->currElem;
    if (iovList == NULL)
    {
        return 1;
    }
    iovOffset = iovIter->offset;
    iovList->iov.ptr[iovOffset] = b;
    ++iovOffset;
    if (iovOffset >= iovList->iov.len)
    {
        iovOffset = 0;
        iovList = iovList->next;
    }
    iovIter->currElem = iovList;
    iovIter->offset = iovOffset;
    return 0;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX size_t whip6_iovIteratorSerializeUInt32AndMoveForward(
        iov_blist_iter_t * iovIter,
        uint32_t d
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    // FIXME iwanicki 2013-06-21:
    // Implement when really necessary.
    (void)iovIter;
    (void)d;
    return 4;
}

#endif /* __WHIP6_MICROC_BASE_DETAIL_IO_VEC_IMPL_H__ */
