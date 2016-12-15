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

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_FRAGMENTATION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_FRAGMENTATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the 6LoWPAN fragmentation functionality.
 * For more information, refer to docs/rfc4944.pdf.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <base/ucError.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ieee154/ucIeee154FrameTypes.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6PacketTypes.h>

/**
 * The state necessary to fragment a single IPv6 packet
 * with 6LoWPAN.
 */
typedef struct lowpan_frag_packet_state_s
{
    struct lowpan_frag_packet_state_s MCS51_STORED_IN_RAM *   next;
    ipv6_packet_t MCS51_STORED_IN_RAM *                       packet;
    lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM *     lowpanHdrs;
    lowpan_header_frag_dgram_size_t                           fragOffset;
    lowpan_header_frag_dgram_tag_t                            fragTag;
} lowpan_frag_packet_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_frag_packet_state_t)



/**
 * The state of a 6LoWPAN fragmenter.
 */
typedef struct lowpan_frag_global_state_s
{
    lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   currentPackets;
    lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   freePackets;
    lowpan_header_frag_dgram_tag_t                     tagGenerator;
    uint8_t                                            fragFlags;
} lowpan_frag_global_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_frag_global_state_t)



/**
 * 6LoWPAN fragmentation flags.
 */
enum
{
    LOWPAN_WHIP6_USE_IPHC = 1,
};


/**
 * Initializes the global 6LoWPAN fragmenter state.
 * @param state The fragmenter state to be initialized.
 * @param pktsArrPtr An array containing
 *   packet fragmentation states (NULL denotes
 *   that no fragmentation is performed and all
 *   packets must fit a single frame).
 * @param pktsArrLen The length of the array with
 *   packet fragmentation states.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanFragmenterInit(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * pktsArrPtr,
        uint8_t pktsArrLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the current 6LoWPAN fragmentation flags.
 * @param state The fragmenter state.
 * @return The current 6LoWPAN fragmentation flags.
 */
#define whip6_lowpanFragmenterGetFlags(state) ((state)->fragFlags)

/**
 * Sets the current 6LoWPAN fragmentation flags.
 * @param state The fragmenter state.
 * @param flags The 6LoWPAN fragmentation flags
 *   to be set.
 */
#define whip6_lowpanFragmenterSetFlags(state, flags) do { (state)->fragFlags = (flags); } while (0)

/**
 * Passes an IPv6 packet to the fragmenter
 * to start fragmenting it.
 * @param state The fragmenter state.
 * @param packet The packet to be passed
 *   for fragmentation. If the function
 *   succeeds, the ownership of this structure
 *   is transfered to the fragmenter; otherwise,
 *   it stays with the caller.
 * @return A token that should be used
 *   in subsequent requests related to the
 *   packet or NULL indicating a failure.
 *   If a valid token is returned it should
 *   later be passed back to the fragmenter
 *   with the whip6_lowpanFragmenterFinishFragmentingIpv6Packet
 *   function.
 * @see whip6_lowpanFragmenterFinishFragmentingIpv6Packet
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * whip6_lowpanFragmenterStartFragmentingIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Associates 6LoWPAN headers that will be added
 * to frames generated for a given token BEFORE
 * the fragmentation header (or unfragmented payload).
 * This function can be called once for a single
 * token or can be called before each frame is requested.
 * However, it must be called.
 * @param state The fragmenter state.
 * @param token The fragmentation token returned
 *   an earlier invocation of the
 *   whip6_lowpanFragmenterStartFragmentingIpv6Packet
 *   function.
 * @param lowpanHdrs The headers to be associated.
 * @return WHIP6_NO_ERROR on success, or an error
 *   code otherwise, in which case the fragmentation
 *   state of the packet remains unmodified.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanFragmenterProvideAdditional6LoWPANHeadersForIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * lowpanHdrs
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Checks whether a next 6LoWPAN fragment of
 * an IPv6 packet exists.
 * @param state The fragmenter state.
 * @param token The fragmentation token returned
 *   an earlier invocation of the
 *   whip6_lowpanFragmenterStartFragmentingIpv6Packet
 *   function.
 * @return Nonzero if the next fragment exists or
 *   zero otherwise.
 */
#define whip6_lowpanFragmenterDoesNextFragmentOfIpv6PacketExist(state, token) \
    ((token)->fragOffset < whip6_ipv6BasicHeaderGetPayloadLength(&(token)->packet->header) + sizeof(ipv6_basic_header_t))

/**
 * Requests a next 6LoWPAN fragment of an IPv6
 * packet to be put into an IEEE 802.15.4 frame.
 * @param state The fragmenter state.
 * @param token The fragmentation token returned
 *   an earlier invocation of the
 *   whip6_lowpanFragmenterStartFragmentingIpv6Packet
 *   function.
 * @param frameInfo The frame into which the
 *   packet is to be fragmented.
 * @return WHIP6_NO_ERROR on success, or an error
 *   code otherwise, in which case the fragmentation
 *   state of the packet remains unmodified.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanFragmenterRequestNextFragmentOfIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frameInfo
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Finishes fragmenting an IPv6 packet.
 * @param state The fragmenter state.
 * @param token The fragmentation token returned
 *   an earlier invocation of the
 *   whip6_lowpanFragmenterStartFragmentingIpv6Packet
 *   function.
 * @return The original IPv6 packet associated with
 *   the token or NULL if the token is not recognized.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanFragmenterFinishFragmentingIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_FRAGMENTATION_H__ */
