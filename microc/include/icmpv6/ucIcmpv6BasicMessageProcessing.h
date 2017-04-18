/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#ifndef __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_PROCESSING_H__
#define __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_PROCESSING_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains type definitions for
 * processing basic ICMPv6 messages.
 * For more information, see docs/rfc4443.pdf
 */

#include <base/ucIoVec.h>
#include <ipv6/ucIpv6AddressTypes.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>


/**
 * Wraps an I/O vector into an IPv6 packet carrying
 * an ICMPv6 message.
 * @param payloadIter An iterator pointing at the I/O
 *   vector to be wrapped.
 * @param payloadLen The length of data in the I/O vector.
 * @param icmpv6HdrPtr A pointer to the ICMPv6 header.
 * @param icmpv6HdrIov The I/O vector element that will
 *   receive the UDP header. Its pointers will be overwritten.
 * @param firstIov The I/O vector element that will
 *   mark the beginning of the message.
 * @param srcAddrOrNull The IPv6 address of the source
 *   or NULL, which indicates an undefined address.
 * @param dstAddr The address of the destination.
 * @return A pointer to the IPv6 packet with the
 *   I/O vector as a ICMPv6 payload or NULL in case of
 *   an error.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6WrapDataIntoOutgoingIpv6PacketCarryingIcmpMessage(
        iov_blist_iter_t MCS51_STORED_IN_RAM * payloadIter,
        size_t payloadLen,
        icmpv6_message_header_t MCS51_STORED_IN_RAM * icmpv6HdrPtr,
        iov_blist_t MCS51_STORED_IN_RAM * icmpv6HdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * firstIov,
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddrOrNull,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Unwraps an I/O vector with the data from an IPv6
 * packet carrying an ICMPv6 message.
 * @param packet The packet.
 * @param payloadIter An iterator pointing at the I/O
 *   vector to be unwrapped.
 * @param payloadLen The length of data in the I/O vector.
 * @param icmpv6HdrIov The I/O vector element that will
 *   receive the UDP header. Its pointers will be overwritten.
 * @param firstIov The I/O vector element that will
 *   mark the beginning of the message.
 * @return Zero if the I/O vector has been unwrapped correctly,
 *   or nonzero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_icmpv6UnwrapDataFromOutgoingIpv6PacketCarryingIcmpMessage(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        iov_blist_iter_t MCS51_STORED_IN_RAM * payloadIter,
        size_t payloadLen,
        iov_blist_t MCS51_STORED_IN_RAM * icmpv6HdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * firstIov
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#endif /* __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_PROCESSING_H__ */
