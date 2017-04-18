/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_NALP_EXTENSION_SOFTWARE_ACKNOWLEDGMENTS_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_NALP_EXTENSION_SOFTWARE_ACKNOWLEDGMENTS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functionality for a no-6LoWPAN
 * extension providing software acknowledgments.
 */

#include <6lowpan/uc6LoWPANNalpExtensionConstants.h>
#include <ieee154/ucIeee154FrameTypes.h>




/**
 * Checks if a given frame is a no-6LoWPAN
 * acknowledgment frame.
 * @param inFrame A pointer to the frame.
 * @param ackSeqNoBufPtr A pointer to a buffer that will
 *   receive the sequence number of the acknowledged frame if
 *   the given frame is an acknowledgment itself.
 * @return Nonzero if a given frame is an acknowledgment
 *   frame or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_lowpanNalpExtSoftwareAcknowledgmentIsAckFrame(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame,
        ieee154_frame_seq_no_t * ackSeqNoBufPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Tries to create a no-6LoWPAN software acknowledgment
 * frame for a given input frame.
 * @param ackFrame A pointer to the frame buffer that
 *   will receive the acknowledgment.
 * @param inFrame A pointer to the input frame.
 * @return Nonzero if the acknowledgment frame has been
 *   generated or zero otherwise..
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_lowpanNalpExtSoftwareAcknowledgmentCreateAckFrame(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * ackFrame,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_NALP_EXTENSION_SOFTWARE_ACKNOWLEDGMENTS_H__ */
