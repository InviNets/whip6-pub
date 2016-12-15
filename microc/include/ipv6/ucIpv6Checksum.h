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

#ifndef __WHIP6_MICROC_IPV6_IPV6_CHECKSUM_H__
#define __WHIP6_MICROC_IPV6_IPV6_CHECKSUM_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains type definitions and
 * functionality related to IPv6 checksum.
 * For more information, refer to docs/rfc2460.pdf.
 */

#include <base/ucTypes.h>
#include <base/ucIoVec.h>
#include <ipv6/ucIpv6AddressTypes.h>


/** An IPv6 checksum. */
typedef uint16_t ipv6_checksum_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_checksum_t)

/** The state necessary to compute an IPv6 checksum. */
typedef struct ipv6_checksum_computation_s
{
    uint32_t   sum;
    uint8_t    parity;
    uint8_t    accum;
} ipv6_checksum_computation_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_checksum_computation_t)



/**
 * Initializes an IPv6 checksum computation.
 * @param comp The computation to be initialized.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6ChecksumComputationInit(
        ipv6_checksum_computation_t * comp
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Provides a checksum computation with a next byte.
 * @param comp The computation.
 * @param b The next byte.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6ChecksumComputationProvideWithOneByte(
        ipv6_checksum_computation_t * comp,
        uint8_t b
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Provides a checksum computation with
 * an array of subsequent bytes.
 * @param comp The computation.
 * @param bufPtr A pointer to the byte array.
 * @param bufLen The length of the byte array.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_ipv6ChecksumComputationProvideWithByteArray(
        ipv6_checksum_computation_t * comp,
        uint8_t MCS51_STORED_IN_RAM const * bufPtr,
        size_t bufLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Provides a checksum computation with
 * a fragment of an I/O vector the beginning
 * of which is pointed at by a given iterator
 * and of a given length. The iterator is
 * advanced as a result of the operation.
 * @param comp The computation.
 * @param iovIter An iterator over the I/O vector.
 * @param fragLen The number of bytes in the fragment.
 * @return The actual number of bytes by which
 *   the iterator has been advanced.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX size_t whip6_ipv6ChecksumComputationProvideWithIovAndAdvanceIovIterator(
        ipv6_checksum_computation_t * comp,
        iov_blist_iter_t * iovIter,
        size_t fragLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds to a checksum computation an IPv6 pseudo header.
 * @param comp The computation.
 * @param srcAddr The source address.
 * @param dstAddr The final destination address.
 * @param ipLen The length.
 * @param nextHdr The next header field.
 * @return The number of bytes in the pseudo header.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX size_t whip6_ipv6ChecksumComputationProvideIpv6PseudoHeader(
        ipv6_checksum_computation_t * comp,
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        uint32_t ipLen,
        uint8_t nextHdr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the checksum obtained in an IPv6 checksum
 * computation.
 * @param comp The computation.
 * @return The checksum value.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX ipv6_checksum_t whip6_ipv6ChecksumComputationFinalize(
        ipv6_checksum_computation_t const * comp
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



#include <ipv6/detail/ucIpv6ChecksumImpl.h>

#endif /* __WHIP6_MICROC_IPV6_IPV6_CHECKSUM_H__ */
