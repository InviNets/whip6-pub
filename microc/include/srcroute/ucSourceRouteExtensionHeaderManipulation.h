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

#ifndef __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_H__
#define __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functions for manipulating
 * an IPv6 extension header that allows for source
 * routing in combination with RPL.
 * For more information, refer to docs/rfc6554.pdf.
 */

#include <srcroute/ucSourceRouteExtensionHeaderTypes.h>



/**
 * Returns the next header field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The next header.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_next_header_field_t whip6_ipv6ExtensionHeaderSourceRouteGetNextHeader(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the next header field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param nh The next header to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetNextHeader(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_next_header_field_t nh
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the header length field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The header length in bytes.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_payload_length_t whip6_ipv6ExtensionHeaderSourceRouteGetHeaderLength(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the header length field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param hl The header length in bytes. Must be
 *   divisible by 8 and smaller than 2048.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetHeaderLength(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_payload_length_t hl
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the routing type field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The routing type. Should be equal to 3.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_extension_header_srh_routing_type_t whip6_ipv6ExtensionHeaderSourceRouteGetRoutingType(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the routing type field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param rt The routing type to set. Should be equal to 3.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetRoutingType(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_routing_type_t rt
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the segments left field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The number of segments left.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_extension_header_srh_segments_left_t whip6_ipv6ExtensionHeaderSourceRouteGetSegmentsLeft(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the segments left field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param sl The number of segments left to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetSegmentsLeft(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_segments_left_t sl
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the CmprI field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The CmprI field.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetCmprI(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the CmprI field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param cmprI The CmprI field to set. Must not be greater than 15.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetCmprI(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t cmprI
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the CmprE field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The CmprE field.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetCmprE(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the CmprE field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param cmprE The CmprE field to set. Must not be greater than 15.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetCmprE(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t cmprE
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the pad field from an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return The pad field.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetPad(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the pad field in an IPv6 extension header
 * for source routing. No error checking is performed.
 * @param hdr The extension header.
 * @param pad The pad field to set. Must not be greater than 7.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetPad(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t pad
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks the reserved field of an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 * @return Zero if the reserved field is correct,
 *   or an nonzero value otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_ipv6ExtensionHeaderSourceRouteCheckReserved(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the reserved field of an IPv6 extension
 * header for source routing.
 * @param hdr The extension header.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteClearReserved(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


#include <srcroute/detail/ucSourceRouteExtensionHeaderManipulationImpl.h>

#endif /* __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_H__ */
