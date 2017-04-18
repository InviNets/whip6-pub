/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_MANIPULATION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic 6LoWPAN frame functions.
 * For more information, refer to docs/rfc4944.pdf
 * and docs/rfc6282.pdf.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>


/**
 * Unpacks a 6LoWPAN header structure from an IEEE 802.15.4
 * data frame. If the frame to be unpacked is not a 6LoWPAN
 * frame, the resulting structure is empty and the next
 * dispatch header is NALP.
 * @param hdrs The header structure to which
 *   the frame will be unpacked.
 * @param frame The frame to be unpacked.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanFrameHeadersUnpack(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Packs a 6LoWPAN header structure into an IEEE 802.15.4
 * data frame.
 * @param hdrs The header structure that is
 *   to be packed into the frame.
 * @param frame The frame to which the structure
 *   will be be packed.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanFrameHeadersPack(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Creates an empty unpacked 6LoWPAN header structure.
 * Subsequent headers can later be added to the structure.
 * @param hdr The header structure to be created.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_lowpanFrameHeadersNew(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Adds a mesh routing header to an unpacked
 * 6LoWPAN header structure. This function always
 * succeeds. Any errors are detected when the header
 * structure is packed.
 * @param hdr The header structure to be modified.
 * @param hopLimit The maximal number of hops.
 * @param srcAddr A pointer to a source address.
 * @param dstAddr A pointer to a destination address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_lowpanFrameHeadersAddMeshHeader(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        uint8_t hopLimit,
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Adds a broadcast 0 header to an unpacked
 * 6LoWPAN header structure. This function always
 * succeeds. Any errors are detected when the header
 * structure is packed.
 * @param hdr The header structure to be modified.
 * @param seqNo The sequence number for the header.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_lowpanFrameHeadersAddBc0Header(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        uint8_t seqNo
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Adds a fragmentation header to an unpacked
 * 6LoWPAN header structure. This function always
 * succeeds. Any errors are detected when the header
 * structure is packed.
 * @param hdr The header structure to be modified.
 * @param tag A tag uniquely identifying the datagram.
 * @param size The entire size of the defragmented datagram.
 * @param offset An offset of the fragment within
 *   the datagram.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_lowpanFrameHeadersAddFragHeader(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        lowpan_header_frag_dgram_tag_t tag,
        lowpan_header_frag_dgram_size_t size,
        lowpan_header_frag_dgram_offset_t offset
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


#define whip6_lowpanFrameHeadersGetMeshHeaderHopLimit(hdrs) (hdrs)->mesh.hopLimit
#define whip6_lowpanFrameHeadersSetMeshHeaderHopLimit(hdrs, hl) (hdrs)->mesh.hopLimit = (hl)
#define whip6_lowpanFrameHeadersGetMeshHeaderSrcAddrPtr(hdrs) (&(hdrs)->mesh.srcAddr)
#define whip6_lowpanFrameHeadersGetMeshHeaderDstAddrPtr(hdrs) (&(hdrs)->mesh.dstAddr)

#define whip6_lowpanFrameHeadersGetBc0HeaderSeqNo(hdrs) (hdrs)->bc0.seqNo

#define whip6_lowpanFrameHeadersGetFragHeaderSize(hdrs) (hdrs)->frag.size
#define whip6_lowpanFrameHeadersGetFragHeaderTag(hdrs) (hdrs)->frag.tag
#define whip6_lowpanFrameHeadersGetFragHeaderOffset(hdrs) (hdrs)->frag.offset

#define whip6_lowpanFrameHeadersHasMeshHeader(hdrs) (((hdrs)->bitmap & LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT) != 0)
#define whip6_lowpanFrameHeadersHasBc0Header(hdrs) (((hdrs)->bitmap & LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT) != 0)
#define whip6_lowpanFrameHeadersHasFragHeader(hdrs) (((hdrs)->bitmap & LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT) != 0)

/**
 * Entries in the bitmap of lowpan_unpacked_frame_headers_t.
 */
enum
{
    LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT = (1U << 0),
    LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT = (1U << 1),
    LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT = (1U << 2),
};

#include <6lowpan/detail/uc6LoWPANHeaderManipulationImpl.h>

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_MANIPULATION_H__ */
