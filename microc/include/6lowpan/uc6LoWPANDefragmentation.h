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

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_DEFRAGMENTATION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_DEFRAGMENTATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the 6LoWPAN defragmentation functionality.
 * For more information, refer to docs/rfc4944.pdf.
 */

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <base/ucError.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ieee154/ucIeee154FrameTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



typedef uint32_t   defrag_time_in_ms_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(defrag_time_in_ms_t)


/**
 * A specification of a 6LoWPAN fragment.
 */
typedef struct lowpan_defrag_frag_spec_s
{
    lowpan_header_frag_dgram_offset_t                        offset;
    lowpan_header_frag_dgram_size_t                          size;
    struct lowpan_defrag_frag_spec_s MCS51_STORED_IN_RAM *   next;
} lowpan_defrag_frag_spec_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_defrag_frag_spec_t)


/**
 * A key of a 6LoWPAN fragment set.
 */
typedef struct lowpan_defrag_frag_set_key_s
{
    lowpan_header_frag_dgram_tag_t                              tag;
    ieee154_addr_t                                              srcLinkAddr;
    ieee154_addr_t                                              dstLinkAddr;
    ieee154_pan_id_t                                            commonPanId;
} lowpan_defrag_frag_set_key_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_defrag_frag_set_key_t)


/**
 * The state necessary to defragment a single IPv6 packet
 * with 6LoWPAN.
 */
typedef struct lowpan_defrag_packet_state_s
{
    struct lowpan_defrag_packet_state_s MCS51_STORED_IN_RAM *   next;
    ipv6_packet_t MCS51_STORED_IN_RAM *                         packet;
    lowpan_defrag_frag_set_key_t                                key;
    lowpan_header_frag_dgram_size_t                             totalSize;
    lowpan_defrag_frag_spec_t                                   firstFragSpec;
    defrag_time_in_ms_t                                         defragStartTime;
} lowpan_defrag_packet_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_defrag_packet_state_t)



/**
 * The state of a 6LoWPAN defragmenter.
 */
typedef struct lowpan_defrag_global_state_s
{
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   currentPackets;
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   lockedPackets;
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   freePackets;
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *      freeAdditionalFragSpecs;
    union
    {
        ieee154_pan_id_t   tmpPanId;
    }                                                    scratchPad;
} lowpan_defrag_global_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_defrag_global_state_t)



/**
 * Initializes the global defragmenter state.
 * @param state The defragmenter state to be initialized.
 * @param pktsArrPtr An array containing
 *   packet defragmentation states (NULL denotes
 *   that no defragmentation is performed and all
 *   packets must fit a single frame).
 * @param fragSpecArrPtr An array containing
 *   fragment specifications (NULL denotes that
 *   fragments cannot be defragmented out of order).
 * @param pktsArrLen The length of the array with
 *   packet defragmentation states.
 * @param fragSpecArrLen The length of the array with
 *   fragment specifications.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanDefragmenterInit(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * pktsArrPtr,
        lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * fragSpecArrPtr,
        uint8_t pktsArrLen,
        uint8_t fragSpecArrLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Check if there is a mesh routing header among
 * the 6LoWPAN headers. If not copies the addresses
 * from the IEEE 802.15.4 frame into the mesh header
 * and sets the hop count to 1. However, it does
 * not set a bit denoting that the header is present.
 * @param frameInfo The given frame for which
 *   to check for the mesh routing header.
 * @param lowpanHdrs The 6LoWPAN headers for the frame.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanDefragmenterCreateVirtualMeshHeaderIfNecessary(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * lowpanHdrs
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Searches for an IPv6 packet a part of which is a
 * given 6LoWPAN frame. If no such packet exists, an attempt
 * is made to allocate a new one. If the allocation fails,
 * a NULL value is returned. In contrast, if an existing or
 * a new packet is in place, it becomes locked. A locked packet
 * is guaranteed to survive timeouts and dumping, and is
 * not subject to further searches by this method.
 * @param state The defragmenter state.
 * @param frameInfo The given frame for which
 *   to seek for an IPv6 packet.
 * @param lowpanHdrs The 6LoWPAN headers for the frame.
 * @param currTimeInMs The current timestamp (in milliseconds).
 * @return An IPv6 packet corresponding to the frame
 *   or NULL if there is no space to allocate such a packet,
 *   or if the packet requires no defragmentation,
 *   or another error has been encountered.
 *   In the former case, the packet becomes locked.
 *   At some point, the caller must unlock it with either the
 *   whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment or
 *   whip6_lowpanDefragmenterUnlockPacket function.
 * @see whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment
 * @see whip6_lowpanDefragmenterUnlockPacket
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs,
        defrag_time_in_ms_t currTimeInMs
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Passes a 6LoWPAN frame with a 6LoWPAN fragmentation
 * header to the defragmenter. Requires that previously the
 * whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt
 * has been called and returned a non-NULL locked defragmented
 * packet structure.
 * @param state The defragmenter state.
 * @param frameInfo The information on the frame
 *   to be passed to the defragmenter. After the function
 *   returns, the object can be reused.
 * @param lowpanHdrs The 6LoWPAN headers for the frame.
 *   After the function returns, the object can be reused.
 * @param lockedDefragPacket The locked defragmented
 *   packet structure returned by the previous invocation
 *   of whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt
 *   for the frame. The ownership of this structure
 *   is passed to the defragmenter.
 * @return A new packet that the frame contributed to
 *   or NULL if no new packet has been generated.
 * @see whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Passes a 6LoWPAN frame without a 6LoWPAN fragmentation
 * header to the defragmenter.
 * @param state The defragmenter state.
 * @param frameInfo The information on the frame
 *   to be passed to the defragmenter. After the function
 *   returns, the object can be reused.
 * @param lowpanHdrs The 6LoWPAN headers for the frame.
 *   After the function returns, the object can be reused.
 * @return A new packet that the frame contained
 *   or NULL if the frame is incorrect.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterPassFrameWithEntireIpv6Packet(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Unlocks a previously locked (by the
 * whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt
 * function) defragmented packet structure.
 * @param state The defragmenter state.
 * @param lockedDefragPacket The locked defragmented
 *   packet structure returned by the previous invocation
 *   of whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt
 *   for the frame. The ownership of this structure
 *   is passed to the defragmenter if the function is
 *   successful.
 * @return WHIP6_NO_ERROR if unlocking succeeded
 *   or WHIP6_ARGUMENT_ERROR if the packet structure was
 *   not locked, in which case the function had no effect.
 * @see whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanDefragmenterUnlockPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Informs the defragmenter that a periodic timeout
 * has occurred.
 * @param state The defragmenter state.
 * @param currTimeInMs The current timestamp (in milliseconds).
 * @param reassemblyTimeout The timeout (in milliseconds)
 *   after the reassembly of a packet is terminated.
 * @return WHIP6_NO_ERROR if the timeout was successfully
 *   processed or WHIP6_STATE_ERROR if there were some packets
 *   locked, and hence, the timeout had no effect.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanDefragmenterPeriodicTimeout(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        defrag_time_in_ms_t currTimeInMs,
        defrag_time_in_ms_t reassemblyTimeoutInMs
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Informs the defragmenter to terminate all reassemblies.
 * @param state The defragmenter state.
 * @return WHIP6_NO_ERROR if the reassemblies were successfully
 *   terminated or WHIP6_STATE_ERROR if there were some packets
 *   locked, and hence, the function had no effect.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_lowpanDefragmenterTerminateAllReassemblies(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_DEFRAGMENTATION_H__ */
