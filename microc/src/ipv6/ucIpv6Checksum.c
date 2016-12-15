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

#include <ipv6/ucIpv6Checksum.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX size_t whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
        ipv6_checksum_computation_t * comp,
        iov_blist_iter_t * iovIter,
        size_t fragLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovList;
    size_t                              iovOffset;
    size_t                              res;

    if (fragLen == 0)
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
    if (res > fragLen)
    {
        res = fragLen;
        whip6_ipv6ChecksumComputationProvideWithByteArray(
                comp,
                iovList->iov.ptr + iovOffset,
                res
        );
        iovIter->offset = iovOffset + res;
    }
    else
    {
        whip6_ipv6ChecksumComputationProvideWithByteArray(
                comp,
                iovList->iov.ptr + iovOffset,
                res
        );
        fragLen -= res;
        iovList = iovList->next;
        iovOffset = 0;
        while (iovList != NULL && fragLen > 0)
        {
            iovOffset = iovList->iov.len;
            if (iovOffset > fragLen)
            {
                iovOffset = fragLen;
                whip6_ipv6ChecksumComputationProvideWithByteArray(
                        comp,
                        iovList->iov.ptr,
                        iovOffset
                );
                res += iovOffset;
                break;
            }
            else
            {
                whip6_ipv6ChecksumComputationProvideWithByteArray(
                        comp,
                        iovList->iov.ptr,
                        iovOffset
                );
                res += iovOffset;
                fragLen -= iovOffset;
                iovList = iovList->next;
                iovOffset = 0;
            }
        }
        iovIter->currElem = iovList;
        iovIter->offset = iovOffset;
    }
    return res;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX size_t whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
        ipv6_checksum_computation_t * comp,
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        uint32_t ipLen,
        uint8_t nextHdr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint16_t tmpLen;

    // NOTICE iwanicki 2013-06-20:
    // We try to optimize this as much as possible
    // by skipping over 16-bit zeroes that do not
    // contribute to the aggregate.
    whip6_ipv6ChecksumComputationProvideWithByteArray(
            comp,
            (uint8_t MCS51_STORED_IN_RAM const *)srcAddr,
            sizeof(ipv6_addr_t)
    );
    whip6_ipv6ChecksumComputationProvideWithByteArray(
            comp,
            (uint8_t MCS51_STORED_IN_RAM const *)dstAddr,
            sizeof(ipv6_addr_t)
    );
    tmpLen = (uint16_t)(ipLen >> 16);
    if (tmpLen != 0)
    {
        whip6_ipv6ChecksumComputationProvideWithOneByte(
                comp,
                (uint8_t)(tmpLen >> 8)
        );
        whip6_ipv6ChecksumComputationProvideWithOneByte(
                comp,
                (uint8_t)(tmpLen)
        );
    }
    tmpLen = (uint16_t)(ipLen);
    whip6_ipv6ChecksumComputationProvideWithOneByte(
            comp,
            (uint8_t)(tmpLen >> 8)
    );
    whip6_ipv6ChecksumComputationProvideWithOneByte(
            comp,
            (uint8_t)(tmpLen)
    );
//    whip6_ipv6ChecksumComputationProvideWithOneByte(
//            comp,
//            (uint8_t)(0x00)
//    );
//    whip6_ipv6ChecksumComputationProvideWithOneByte(
//            comp,
//            (uint8_t)(0x00)
//    );
    whip6_ipv6ChecksumComputationProvideWithOneByte(
            comp,
            (uint8_t)(0x00)
    );
    whip6_ipv6ChecksumComputationProvideWithOneByte(
            comp,
            (uint8_t)(nextHdr)
    );
    return (sizeof(ipv6_addr_t) << 1) + 8;
}
