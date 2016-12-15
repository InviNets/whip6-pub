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

#ifndef __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_HEADER_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_HEADER_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_MANIPULATION_H__ */

#include <base/ucString.h>
#include <ieee154/ucIeee154AddressManipulation.h>



/**
 * 6LoWPAN dispatch values.
 */
enum
{
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_NALP = 0x00,
    LOWPAN_DISPATCH_LENGTH_NALP = 2,
    LOWPAN_DISPATCH_MASK_NALP = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_NALP)) & 0xff),
    /** see RFC 6282 */
    LOWPAN_DISPATCH_PATTERN_ESC = 0x40,
    LOWPAN_DISPATCH_LENGTH_ESC = 8,
    LOWPAN_DISPATCH_MASK_ESC = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_ESC)) & 0xff),
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_IPV6 = 0x41,
    LOWPAN_DISPATCH_LENGTH_IPV6 = 8,
    LOWPAN_DISPATCH_MASK_IPV6 = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_IPV6)) & 0xff),
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_LOWPAN_BC0 = 0x50,
    LOWPAN_DISPATCH_LENGTH_LOWPAN_BC0 = 8,
    LOWPAN_DISPATCH_MASK_LOWPAN_BC0 = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_LOWPAN_BC0)) & 0xff),
    /** see RFC 6282 */
    LOWPAN_DISPATCH_PATTERN_LOWPAN_IPHC = 0x60,
    LOWPAN_DISPATCH_LENGTH_LOWPAN_IPHC = 3,
    LOWPAN_DISPATCH_MASK_LOWPAN_IPHC = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_LOWPAN_IPHC)) & 0xff),
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_MESH = 0x80,
    LOWPAN_DISPATCH_LENGTH_MESH = 2,
    LOWPAN_DISPATCH_MASK_MESH = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_MESH)) & 0xff),
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_FRAG1 = 0xc0,
    LOWPAN_DISPATCH_LENGTH_FRAG1 = 5,
    LOWPAN_DISPATCH_MASK_FRAG1 = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_FRAG1)) & 0xff),
    /** see RFC 4944 */
    LOWPAN_DISPATCH_PATTERN_FRAGN = 0xe0,
    LOWPAN_DISPATCH_LENGTH_FRAGN = 5,
    LOWPAN_DISPATCH_MASK_FRAGN = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_FRAGN)) & 0xff),
    /** our extension */
    LOWPAN_DISPATCH_LENGTH_FRAGX = 5,
    LOWPAN_DISPATCH_PATTERN_FRAGX = 0xc0,
    LOWPAN_DISPATCH_MASK_FRAGX_UNMASKED = ((0xffU << (8 - LOWPAN_DISPATCH_LENGTH_FRAGX)) & 0xff),
    LOWPAN_DISPATCH_MASK_FRAGX = (LOWPAN_DISPATCH_MASK_FRAGX_UNMASKED & 0xdf),

};



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_lowpanFrameHeadersNew(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdrs->bitmap = 0;
    hdrs->nextOffset = 0;
}



WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_lowpanFrameHeadersAddMeshHeader(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        uint8_t hopLimit,
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_INLINE_DECL_SUFFIX
{
    hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT;
    hdrs->mesh.hopLimit = hopLimit;
    whip6_ieee154AddrAnyCpy(srcAddr, &hdrs->mesh.srcAddr);
    whip6_ieee154AddrAnyCpy(dstAddr, &hdrs->mesh.dstAddr);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_lowpanFrameHeadersAddBc0Header(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        uint8_t seqNo
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT;
    hdrs->bc0.seqNo = seqNo;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_lowpanFrameHeadersAddFragHeader(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        lowpan_header_frag_dgram_tag_t tag,
        lowpan_header_frag_dgram_size_t size,
        lowpan_header_frag_dgram_offset_t offset
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT;
    hdrs->frag.tag = tag;
    hdrs->frag.size = size;
    hdrs->frag.offset = offset;
}



#endif /* __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_HEADER_MANIPULATION_IMPL_H__ */
