/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_HEADER_COMPRESSION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_HEADER_COMPRESSION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 header compression in 6LoWPAN.
 * For more information, refer to docs/rfc4944.pdf
 * and docs/rfc6282.pdf.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * Unpacks a raw IPv6 packet header from a frame
 * into a packet prototype.
 * @param frame The original frame containing the
 *   packet data.
 * @param hdrs The unpacked 6LoWPAN header structure for
 *   the frame.
 * @param packet A prototype of the packet to which the
 *   information from the frame will be copied.
 * @param identicalBufPtrOrNull A pointer to a variable
 *   that will receive nonzero if the contents of
 *   the frame were the same as the contents of the
 *   prototype or zero otherwise. Can be NULL.
 * @return The number of bytes copied to the IPv6
 *   packet prototype, or zero indicating an error.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ieee154_frame_length_t whip6_lowpanRawIpv6HeaderUnpack(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * hdrs,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        uint8_t * identicalBufPtrOrNull
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Packs a raw IPv6 packet header from a packet
 * into a frame. The length of the frame is set
 * appropriately if the function returns
 * a nonzero value.
 * @param frame The target frame containing into
 *   which the packet will be packed.
 * @param hdrs The unpacked 6LoWPAN header structure for
 *   the frame.
 * @param packet The packet from which the
 *   information will be copied.
 * @return The number of IPv6 packet bytes copied
 *   to the frame, or zero indicating an error.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ieee154_frame_length_t whip6_lowpanRawIpv6HeaderPack(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * hdrs,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;



#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_HEADER_COMPRESSION_H__ */
