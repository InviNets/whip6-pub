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

#ifndef __WHIP6_MICROC_IPV6_DETAIL_IPV6_CHECKSUM_IMPL_H__
#define __WHIP6_MICROC_IPV6_DETAIL_IPV6_CHECKSUM_IMPL_H__

#ifndef __WHIP6_MICROC_IPV6_IPV6_CHECKSUM_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__ */



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6ChecksumComputationInit(
        ipv6_checksum_computation_t * comp
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    comp->sum = 0;
    comp->parity = 0;
    comp->accum = 0;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6ChecksumComputationProvideWithOneByte(
        ipv6_checksum_computation_t * comp,
        uint8_t b
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t parity;
    parity = (comp->parity + 1) & 0x01;
    comp->parity = parity;
    if (parity == 0)
    {
        uint16_t part = ((uint16_t)(comp->accum) << 8) | b;
        /* comp->accum = 0; */
        comp->sum += part;
    }
    else
    {
        comp->accum = b;
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6ChecksumComputationProvideWithByteArray(
        ipv6_checksum_computation_t * comp,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint32_t    sum;
    uint16_t    part;
    uint8_t     parity;

    if (bufLen == 0 || bufPtr == NULL)
    {
        return;
    }
    sum = comp->sum;
    parity = comp->parity;
    // Handle the left-over byte from the computation.
    if (parity != 0)
    {
        part = ((uint16_t)(comp->accum) << 8) | (*bufPtr);
        sum += part;
        ++bufPtr;
        --bufLen;
    }
    // Check if we will have a left-over byte
    // after processing the entire array.
    if ((bufLen & 0x01) != 0)
    {
        parity = 1;
        --bufLen;
    }
    else
    {
        parity = 0;
    }
    // Handle byte pairs in the middle of the array.
    while (bufLen > 0)
    {
        part = (uint16_t)(*bufPtr) << 8;
        ++bufPtr;
        part |= *bufPtr;
        ++bufPtr;
        sum += part;
        bufLen -= 2;
    }
    comp->sum = sum;
    comp->parity = parity;
    // Handle the left-over byte if necessary.
    if (parity != 0)
    {
        comp->accum = *bufPtr;
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX ipv6_checksum_t whip6_ipv6ChecksumComputationFinalize(
        ipv6_checksum_computation_t const * comp
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint32_t   sum;
    uint16_t   part;

    sum = comp->sum;
    if (comp->parity != 0)
    {
        part = (uint16_t)(comp->accum) << 8;
        sum += part;
    }
    part = sum >> 16;
    while (part != 0)
    {
        sum = (sum & 0xffffU) + part;
        part = sum >> 16;
    }
    sum = ~sum;
    return (ipv6_checksum_t)sum;
}


#endif /* __WHIP6_MICROC_IPV6_DETAIL_IPV6_CHECKSUM_IMPL_H__ */
