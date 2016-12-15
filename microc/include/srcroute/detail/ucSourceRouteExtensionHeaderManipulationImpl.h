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

#ifndef __WHIP6_MICROC_SRCROUTE_DETAIL_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_SRCROUTE_DETAIL_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_next_header_field_t whip6_ipv6ExtensionHeaderSourceRouteGetNextHeader(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->nextHdr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetNextHeader(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_next_header_field_t nh
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->nextHdr = nh;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_payload_length_t whip6_ipv6ExtensionHeaderSourceRouteGetHeaderLength(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return ((ipv6_payload_length_t)hdr->hdrExtLen) << 3;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetHeaderLength(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_payload_length_t hl
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->hdrExtLen = (uint8_t)(hl >> 3);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_extension_header_srh_routing_type_t whip6_ipv6ExtensionHeaderSourceRouteGetRoutingType(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->routingType;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetRoutingType(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_routing_type_t rt
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->routingType = rt;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_extension_header_srh_segments_left_t whip6_ipv6ExtensionHeaderSourceRouteGetSegmentsLeft(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->segmentsLeft;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetSegmentsLeft(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_segments_left_t sl
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->segmentsLeft = sl;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetCmprI(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->cmprX >> 4;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetCmprI(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t cmprI
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->cmprX &= 0x0f;
    hdr->cmprX |= cmprI << 4;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetCmprE(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (hdr->cmprX & 0x0f);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetCmprE(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t cmprE
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->cmprX &= 0xf0;
    hdr->cmprX |= (cmprE & 0x0f);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_extension_header_srh_num_octets_t whip6_ipv6ExtensionHeaderSourceRouteGetPad(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->padAndReserved[0] >> 4;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteSetPad(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr,
        ipv6_extension_header_srh_num_octets_t pad
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->padAndReserved[0] &= 0x0f;
    hdr->padAndReserved[0] |= pad << 4;
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_ipv6ExtensionHeaderSourceRouteCheckReserved(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (hdr->padAndReserved[0] & 0x0f) != 0x00 ||
            hdr->padAndReserved[1] != 0x00 ||
            hdr->padAndReserved[2] != 0x00;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteClearReserved(
        ipv6_extension_header_srh_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->padAndReserved[0] &= 0xf0;
    hdr->padAndReserved[1] = 0x00;
    hdr->padAndReserved[2] = 0x00;
}


#endif /* __WHIP6_MICROC_SRCROUTE_DETAIL_SOURCE_ROUTE_EXTENSION_HEADER_MANIPULATION_IMPL_H__ */
