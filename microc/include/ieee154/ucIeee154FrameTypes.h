/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_FRAME_TYPES_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_FRAME_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IEEE 802.15.4 frame type definitions.
 * For more information, refer to docs/802.15.4-2003.pdf.
 */

#include <ieee154/ucIeee154AddressTypes.h>


/**
 * Information about
 * an IEEE 802.15.4 data frame.
 */
typedef struct ieee154_dframe_info_s
{
    uint8_t MCS51_STORED_IN_RAM *   bufferPtr;
    uint8_t                         bufferLen;
    uint8_t                         frameFlags;
    uint8_t                         payloadAndDstAddrOff; // 5 hi bits for payload; 3 lo bits for dst addr
    uint8_t                         srcPanAndAddrOff;     // 4 hi bits for pan; 4 lo bits for addr
} ieee154_dframe_info_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_dframe_info_t)



enum
{
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT = 0,
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT = 2,
    IEEE154_DFRAME_INFO_FLAG_INTER_PAN_SHIFT = 4,
};

/**
 * Flags that can be associated with
 * a data frame.
 */
enum ieee154_dframe_info_flags_e
{
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_NONE = 0, // (IEEE154_ADDR_MODE_NONE << IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHORT = (IEEE154_ADDR_MODE_SHORT << IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_EXT = (IEEE154_ADDR_MODE_EXT << IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_NONE = 0, // (IEEE154_ADDR_MODE_NONE << IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHORT = (IEEE154_ADDR_MODE_SHORT << IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_EXT = (IEEE154_ADDR_MODE_EXT << IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT),
    IEEE154_DFRAME_INFO_FLAG_INTER_PAN = (1 << IEEE154_DFRAME_INFO_FLAG_INTER_PAN_SHIFT),
};

/** A length of an IEEE 802.15.4 frame. */
typedef uint8_t ieee154_frame_length_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_frame_length_t)

/** A sequence number associated with IEEE 802.15.4 frames. */
typedef uint8_t ieee154_frame_seq_no_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_frame_seq_no_t)

#endif /* __WHIP6_MICROC_IEEE154_IEEE154_FRAME_TYPES_H__ */
