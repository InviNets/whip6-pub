/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_TYPES_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic header types of 6LoWPAN.
 * For more information, refer to docs/rfc4944.pdf
 * and docs/rfc6282.pdf.
 */

#include <base/ucTypes.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ieee154/ucIeee154FrameTypes.h>



/** A hop limit in a 6LoWPAN mesh routing header. */
typedef uint8_t   lowpan_header_mesh_hop_limit_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_header_mesh_hop_limit_t)

/**
 * An unpacked 6LoWPAN mesh routing header.
 */
typedef struct lowpan_unpacked_header_mesh_s
{
    lowpan_header_mesh_hop_limit_t   hopLimit;
    ieee154_addr_t                   srcAddr;
    ieee154_addr_t                   dstAddr;
} lowpan_unpacked_header_mesh_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_unpacked_header_mesh_t)



/** A sequence number in a 6LoWPAN broadcast header. */
typedef uint8_t   lowpan_header_bc0_seq_no_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_header_bc0_seq_no_t)

/**
 * An unpacked 6LoWPAN broadcast header.
 */
typedef struct lowpan_unpacked_header_bc0_s
{
    lowpan_header_bc0_seq_no_t   seqNo;
} lowpan_unpacked_header_bc0_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_unpacked_header_bc0_t)



/** A datagram tag in a 6LoWPAN fragment header. */
typedef uint16_t   lowpan_header_frag_dgram_tag_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_header_frag_dgram_tag_t)
/** A datagram size in a 6LoWPAN fragment header. */
typedef uint16_t   lowpan_header_frag_dgram_size_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_header_frag_dgram_size_t)
/** A datagram offset in a 6LoWPAN fragment header. */
typedef uint16_t   lowpan_header_frag_dgram_offset_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_header_frag_dgram_offset_t)

/**
 * An unpacked 6LoWPAN fragmentation header.
 */
typedef struct lowpan_unpacked_header_frag_s
{
    lowpan_header_frag_dgram_tag_t      tag;
    lowpan_header_frag_dgram_size_t     size;
    lowpan_header_frag_dgram_offset_t   offset;
} lowpan_unpacked_header_frag_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_unpacked_header_frag_t)



/**
 * Unpacked 6LoWPAN frame information.
 */
typedef struct lowpan_unpacked_frame_headers_s
{
    uint8_t                         bitmap;
    // NOTICE iwanicki 2013-01-22:
    // The nextOffset field is valid only after the
    // header has been validated, that is, after
    // the header has been either unpacked or packed.
    uint8_t                         nextOffset;
    lowpan_unpacked_header_frag_t   frag;
    lowpan_unpacked_header_mesh_t   mesh;
    lowpan_unpacked_header_bc0_t    bc0;
} lowpan_unpacked_frame_headers_t;
MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_unpacked_frame_headers_t)

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_HEADER_TYPES_H__ */
