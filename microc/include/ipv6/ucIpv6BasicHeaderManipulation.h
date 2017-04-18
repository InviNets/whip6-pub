/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__
#define __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 header manipulation functions.
 * For more information, refer to the wikipedia.
 */

#include <ipv6/ucIpv6BasicHeaderTypes.h>

/**
 * Returns the version field from an IPv6 header.
 * @return The IPv6 protocol version.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_protocol_version_t whip6_ipv6BasicHeaderGetVersion(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the version field in an IPv6 header.
 * No error checking is performed.
 * @param ver The version to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetVersion(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_protocol_version_t ver
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the traffic class field from an IPv6 header.
 * @return The traffic class.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_traffic_class_t whip6_ipv6BasicHeaderGetTrafficClass(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the traffic class field in an IPv6 header.
 * No error checking is performed.
 * @param tc The traffic class to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetTrafficClass(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_traffic_class_t tc
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the flow label field from an IPv6 header.
 * @return The flow label.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_flow_label_t whip6_ipv6BasicHeaderGetFlowLabel(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the flow label field in an IPv6 header.
 * No error checking is performed.
 * @param fl The flow label to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetFlowLabel(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_flow_label_t fl
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the payload length field from an IPv6 header.
 * @return The payload length.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_payload_length_t whip6_ipv6BasicHeaderGetPayloadLength(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the payload length field in an IPv6 header.
 * No error checking is performed.
 * @param pl The payload length to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetPayloadLength(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_payload_length_t pl
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the next header field from an IPv6 header.
 * @return The next header.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_next_header_field_t whip6_ipv6BasicHeaderGetNextHeader(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the next header field in an IPv6 header.
 * No error checking is performed.
 * @param nh The next header to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetNextHeader(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_next_header_field_t nh
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the hop limit field from an IPv6 header.
 * @return The hop limit.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_hop_limit_t whip6_ipv6BasicHeaderGetHopLimit(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the hop limit field in an IPv6 header.
 * No error checking is performed.
 * @param hl The hop limit to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6BasicHeaderSetHopLimit(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_hop_limit_t hl
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to the source address
 * field in an IPv6 header. The pointer
 * can be used only for reading.
 * @return A pointer to the source address..
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM const * whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to the source address
 * field in an IPv6 header. The pointer
 * can be used for reading and writing.
 * @return A pointer to the source address..
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to the destination address
 * field in an IPv6 header. The pointer
 * can be used only for reading.
 * @return A pointer to the destination address..
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM const * whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to the destination address
 * field in an IPv6 header. The pointer
 * can be used for reading and writing.
 * @return A pointer to the destination address..
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



#include <ipv6/detail/ucIpv6BasicHeaderManipulationImpl.h>

#endif /* __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__ */
