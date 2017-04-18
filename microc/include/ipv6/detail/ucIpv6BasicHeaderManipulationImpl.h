/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_DETAIL_IPV6_BASIC_HEADER_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_IPV6_DETAIL_IPV6_BASIC_HEADER_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_MANIPULATION_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_protocol_version_t whip6_ipv6BasicHeaderGetVersion(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (ipv6_protocol_version_t)(hdr->verTcFl[0] >> 4);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetVersion(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_protocol_version_t ver
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->verTcFl[0] &= 0x0f;
    hdr->verTcFl[0] |= (((uint8_t)ver) << 4);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_traffic_class_t whip6_ipv6BasicHeaderGetTrafficClass(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (ipv6_traffic_class_t)(
            (hdr->verTcFl[0] << 4) | (hdr->verTcFl[1] >> 4));
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetTrafficClass(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_traffic_class_t tc
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->verTcFl[0] &= 0xf0;
    hdr->verTcFl[0] |= (((uint8_t)tc) >> 4);
    hdr->verTcFl[1] &= 0x0f;
    hdr->verTcFl[1] |= (((uint8_t)tc) << 4);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_flow_label_t whip6_ipv6BasicHeaderGetFlowLabel(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (ipv6_flow_label_t)(((uint32_t)(hdr->verTcFl[1] & 0x0f) << 16) |
            (((uint16_t)(hdr->verTcFl[2]) << 8) | hdr->verTcFl[3]));
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetFlowLabel(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_flow_label_t fl
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->verTcFl[3] = (uint8_t)fl;
    hdr->verTcFl[2] = (uint8_t)(fl >> 8);
    hdr->verTcFl[1] &= 0xf0;
    hdr->verTcFl[1] |= (uint8_t)(fl >> 16) & 0x0f;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_payload_length_t whip6_ipv6BasicHeaderGetPayloadLength(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return ((uint16_t)(hdr->payloadLen[0]) << 8) | hdr->payloadLen[1];
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetPayloadLength(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_payload_length_t pl
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->payloadLen[0] = (uint8_t)(pl >> 8);
    hdr->payloadLen[1] = (uint8_t)pl;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_next_header_field_t whip6_ipv6BasicHeaderGetNextHeader(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->nextHdr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetNextHeader(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_next_header_field_t nh
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->nextHdr = nh;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_hop_limit_t whip6_ipv6BasicHeaderGetHopLimit(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return hdr->hopLimit;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ipv6BasicHeaderSetHopLimit(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_hop_limit_t hl
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdr->hopLimit = hl;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM const * whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &hdr->srcAddr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &hdr->srcAddr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM const * whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
        ipv6_basic_header_t MCS51_STORED_IN_RAM const * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &hdr->dstAddr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_addr_t MCS51_STORED_IN_RAM * whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &hdr->dstAddr;
}


#endif /* __WHIP6_MICROC_IPV6_DETAIL_IPV6_BASIC_HEADER_MANIPULATION_IMPL_H__ */
