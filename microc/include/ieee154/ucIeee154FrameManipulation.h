/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_FRAME_MANIPULATION_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_FRAME_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic IEEE 802.15.4 frame functions.
 * For more information, refer to docs/802.15.4-2003.pdf.
 */

#include <base/ucError.h>
#include <ieee154/ucIeee154FrameTypes.h>



/**
 * Constructs information on a given (empty) data
 * frame. Such information can be subsequently used
 * to fill in the frame.
 * @param frame A pointer to the information
 *   to be constructed.
 * @param bufPtr A pointer to the buffer that
 *   will hold the frame data.
 * @param bufLen The maximal length of the buffer.
 * @param flags The flags used to create the frame.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_ieee154DFrameInfoNew(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen,
        uint8_t flags
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Reinitializes a given frame for a given source and
 * destination addresses and PAN identifiers.
 * @param dstAddr A pointer to the destination address.
 * @param srcAddr A pointer to the source address.
 * @param dstPanId A pointer to the destination PAN identifier.
 * @param srcPanIdOrNull A pointer to the source PAN
 *   identifier or NULL if the source PAN identifier is to
 *   be the same as the destination identifier.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_ieee154DFrameInfoReinitializeFrameForAddresses(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * dstPanId,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * srcPanIdOrNull
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Reinitializes a given output frame to be a reply
 * frame for a given input frame, that is, to be a
 * frame that has source and destination addresses
 * reversed compare to the input frame.
 * @param outFrame The output frame.
 * @param inFrame The input frame.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_ieee154DFrameInfoReinitializeFrameInOppositeDirection(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * outFrame,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Constructs information on a a given (presumably
 * valid) data frame. Such information can be subsequently
 * used to read data from the frame.
 * Note that this function DOES NOT perform any
 * CRC checks. These are assumed to have been
 * performed earlier.
 * @param frame A pointer to the information
 *   to be constructed.
 * @param bufPtr A pointer to the buffer that
 *   holds the frame data.
 * @param bufLen The maximal length of the buffer.
 *   Note that this is NOT the actual size of the
 *   data in the buffer. The size is derived automatically
 *   by this functions.
 * @return WHIP6_NO_ERROR on success, or an error code
 *   otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX whip6_error_t whip6_ieee154DFrameInfoExisting(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Checks if a given IEEE 802.15.4 data frame
 * is meant for the present node.
 * @param frame The frame to be checked.
 * @param panIdPtrOrNull A pointer to the PAN ID
 *   of the present node or NULL if the PAN ID
 *   is not to be checked.
 * @param shrtAddrPtrOrNull A pointer to the
 *   short address of the present node or NULL
 *   if the node has no short address.
 * @param extAddrPtrOrNull A pointer to the
 *   extended address of the present node or
 *   NULL if the node has no extended address.
 * @return Nonzero if the frame can be accepted
 *   by the present node or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ieee154DFrameInfoCheckIfDestinationMatches(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panIdPtrOrNull,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * shrtAddrPtrOrNull,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * extAddrPtrOrNull
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Checks if a given IEEE 802.15.4 data frame
 * is destined to a broadcast address.
 * @param frame The frame to be checked.
 * @return Nonzero if the frame is destined to a
 *   broadcast address or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ieee154DFrameInfoCheckIfDestinationIsBroadcast(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the total length of the data frame excluding the
 * length field. The returned value is essentially
 * the length of the MAC frame as defined in the
 * 802.15.4 standard specification.
 * @param frame The frame for which the
 *   length is to be returned.
 * @return The frame length.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_frame_length_t whip6_ieee154DFrameGetMacDataLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to a buffer that stores the data frame
 * excluding the length field. The returned value is essentially
 * a pointer to the MAC frame as defined in the
 * 802.15.4 standard specification.
 * @param frame The frame for which the
 *   pointer is to be returned.
 * @return The pointer to the frame's buffer.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameGetMacDataPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the Acknowledge request bit in the FCF.
 * @param frame The frame for which the bit is to be set.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ieee154DFrameSetFCFACKRequest(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Returns the sequence number associated with a data frame.
 * @param frame The frame for which the
 *   sequence number is to be returned.
 * @return The sequence number.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_frame_seq_no_t whip6_ieee154DFrameGetSeqNo(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the sequence number associated with a data frame.
 * @param frame The frame for which the
 *   sequence number is to be set.
 * @param seqNo The sequence number to be set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameSetSeqNo(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_seq_no_t seqNo
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the source address associated with a data frame.
 * @param frame The frame for which the
 *   address is to be returned.
 * @param addr A buffer that will receive the address.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ieee154DFrameGetSrcAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Sets the source address associated with a data frame.
 * No checks regarding the address are performed.
 * @param frame The frame for which the
 *   address is to be set.
 * @param addr The address to set.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ieee154DFrameSetSrcAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the destination address associated with a data frame.
 * @param frame The frame for which the
 *   address is to be returned.
 * @param addr A buffer that will receive the address.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ieee154DFrameGetDstAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Sets the destination address associated with a data frame.
 * No checks regarding the address are performed.
 * @param frame The frame for which the
 *   address is to be set.
 * @param addr The address to set.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ieee154DFrameSetDstAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the destination PAN ID associated with a data frame.
 * @param frame The frame for which the
 *   PAN ID is to be returned.
 * @param panId A buffer that will receive the PAN ID.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameGetDstPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * panId
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the destination PAN ID associated with a data frame.
 * @param frame The frame for which the
 *   PAN ID is to be set.
 * @param panId The PAN ID to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameSetDstPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the source PAN ID associated with a data frame.
 * No checks are performed whether the PAN ID actually
 * exists in the frame (for intra-PAN frames it does not).
 * @param frame The frame for which the
 *   PAN ID is to be returned.
 * @param panId A buffer that will receive the PAN ID.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameGetSrcPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * panId
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the source PAN ID associated with a data frame.
 * No checks are performed whether the PAN ID actually
 * exists in the frame (for intra-PAN frames it does not).
 * @param frame The frame for which the
 *   PAN ID is to be set.
 * @param panId The PAN ID to set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameSetSrcPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


#define whip6_ieee154DFrameIsInterPan(frame) (((frame)->frameFlags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) != 0)
#define whip6_ieee154DFrameIsIntraPan(frame) (((frame)->frameFlags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) == 0)

#define whip6_ieee154DFrameGetOffsetDstPanId(frame) (IEEE154_DFRAME_INITIAL_OFFSET)
#define whip6_ieee154DFrameGetOffsetDstAddr(frame) (IEEE154_DFRAME_INITIAL_OFFSET + ((frame)->payloadAndDstAddrOff & 0x07))
#define whip6_ieee154DFrameGetOffsetSrcPanId(frame) (IEEE154_DFRAME_INITIAL_OFFSET + ((frame)->srcPanAndAddrOff >> 4))
#define whip6_ieee154DFrameGetOffsetSrcAddr(frame) (IEEE154_DFRAME_INITIAL_OFFSET + ((frame)->srcPanAndAddrOff & 0x0f))
#define whip6_ieee154DFrameGetOffsetPayload(frame) (IEEE154_DFRAME_INITIAL_OFFSET + ((frame)->payloadAndDstAddrOff >> 3))

#define whip6_ieee154DFrameGetModeDstAddr(frame) (((frame)->frameFlags >> IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)
#define whip6_ieee154DFrameGetModeSrcAddr(frame) (((frame)->frameFlags >> IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)


/**
 * Returns the maximal length of the payload in
 * a data frame.
 * @param frame The frame for which the
 *   maximal payload length is to be returned.
 * @return The maximal length of the payload.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_frame_length_t whip6_ieee154DFrameMaxPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a pointer to the payload of a data frame.
 * This method is unsafe in that it does not perform
 * any checks to verify whether the payload is valid.
 * @param frame The frame for which the
 *   pointer payload is to be returned.
 * @return A pointer to the data payload.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameUnsafeGetPayloadPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


/**
 * Returns a pointer to the payload of a data frame.
 * @param frame The frame for which the
 *   pointer payload is to be returned.
 * @param len The requested length of the
 *   payload. The length is compared not
 *   against the actual payload length
 *   (which may not yet be set), but against
 *   the frame buffer length.
 * @return A pointer to the data payload or
 *   NULL if the requested payload length
 *   is too large.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameGetPayloadPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_length_t len
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the current length of the payload
 * of a data frame.
 * @param frame The frame for which the
 *   payload length is to be returned.
 * @return The length of the payload.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_frame_length_t whip6_ieee154DFrameGetPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the current length of the payload of a data frame.
 * No checks are performed as to whether the length
 * is valid. It is assumed that the payload
 * was earlier obtained with the appropriate checks.
 * @param frame The frame for which the
 *   payload length is to be set.
 * @param len The length of the payload to be set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameSetPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_length_t len
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the CRC associated with a data frame.
 * @param frame The frame for which the
 *   CRC is to be returned.
 * @return The CRC.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint16_t whip6_ieee154DFrameGetCrc(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets the CRC associated with a data frame.
 * @param frame The frame for which the
 *   CRC is to be set.
 * @param crcVal The CRC to be set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154DFrameSetCrc(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        uint16_t crcVal
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



#include <ieee154/detail/ucIeee154FrameManipulationImpl.h>

#endif /* __WHIP6_MICROC_IEEE154_IEEE154_FRAME_MANIPULATION_H__ */
