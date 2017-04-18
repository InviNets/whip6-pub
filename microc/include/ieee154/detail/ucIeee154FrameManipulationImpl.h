/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_FRAME_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_FRAME_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_FRAME_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IEEE154_IEEE154_FRAME_MANIPULATION_H__ */


/**
 * Some constants that should not be used externally.
 */
enum
{
    IEEE154_DFRAME_MINIMAL_SIZE = 6,
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_OFFSET = 0,
    IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_MASK = 0x3,
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_OFFSET = 2,
    IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_MASK = 0x3,
    IEEE154_DFRAME_TYPE = 0x1,
    IEEE154_DFRAME_INITIAL_OFFSET = 4,

    /*
     * By default we let the radio layer handle CRC. To enable CRC handling
     * (not implemented yet in other places than here BTW), set this to 2.
     */
    IEEE154_DFRAME_CRC_SIZE = 0,
};


WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_frame_length_t whip6_ieee154DFrameGetMacDataLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return frame->bufferPtr[0];
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameGetMacDataPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &(frame->bufferPtr[1]);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_frame_seq_no_t whip6_ieee154DFrameGetSeqNo(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return frame->bufferPtr[3];
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameSetSeqNo(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_seq_no_t seqNo
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    frame->bufferPtr[3] = seqNo;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameGetDstPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * panId
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *  ptr;
    ptr = &(frame->bufferPtr[whip6_ieee154DFrameGetOffsetDstPanId(frame)]);
    panId->data[0] = *ptr;
    ++ptr;
    panId->data[1] = *ptr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameSetDstPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *  ptr;
    ptr = &(frame->bufferPtr[whip6_ieee154DFrameGetOffsetDstPanId(frame)]);
    *ptr = panId->data[0];
    ++ptr;
    *ptr = panId->data[1];
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameGetSrcPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * panId
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *  ptr;
    uint8_t offset = whip6_ieee154DFrameGetOffsetSrcPanId(frame);
    ptr = &(frame->bufferPtr[offset]);
    panId->data[0] = *ptr;
    ++ptr;
    panId->data[1] = *ptr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameSetSrcPanId(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *  ptr;
    uint8_t offset = whip6_ieee154DFrameGetOffsetSrcPanId(frame);
    ptr = &(frame->bufferPtr[offset]);
    *ptr = panId->data[0];
    ++ptr;
    *ptr = panId->data[1];
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_frame_length_t whip6_ieee154DFrameMaxPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return frame->bufferLen -
            (frame->payloadAndDstAddrOff >> 3) -
            (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE);
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameUnsafeGetPayloadPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t offset = (frame->payloadAndDstAddrOff >> 3) + IEEE154_DFRAME_INITIAL_OFFSET;
    return &(frame->bufferPtr[offset]);
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t MCS51_STORED_IN_RAM * whip6_ieee154DFrameGetPayloadPtr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_length_t len
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    uint8_t offset = (frame->payloadAndDstAddrOff >> 3) + IEEE154_DFRAME_INITIAL_OFFSET;
    if (len + offset + IEEE154_DFRAME_CRC_SIZE > frame->bufferLen)
    {
        return NULL;
    }
    return &(frame->bufferPtr[offset]);
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_frame_length_t whip6_ieee154DFrameGetPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return frame->bufferPtr[0] -
            (frame->payloadAndDstAddrOff >> 3) -
            (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE - 1);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameSetPayloadLen(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_frame_length_t len
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    len +=
            (frame->payloadAndDstAddrOff >> 3) +
            (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE - 1);
    frame->bufferPtr[0] = len;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint16_t whip6_ieee154DFrameGetCrc(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if (IEEE154_DFRAME_CRC_SIZE == 0)
    {
        return 0;
    }
    else
    {
        uint16_t res = frame->bufferPtr[frame->bufferPtr[0]];
        res = (res << 8) | (uint8_t)(frame->bufferPtr[frame->bufferPtr[0] - 1]);
        return res;
    }
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154DFrameSetCrc(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        uint16_t crcVal
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if (IEEE154_DFRAME_CRC_SIZE == 0)
    {
        // Do nothing.
    }
    else
    {
        frame->bufferPtr[frame->bufferPtr[0] - 1] = (uint8_t)crcVal;
        frame->bufferPtr[frame->bufferPtr[0]] = (uint8_t)(crcVal >> 8);
    }
}


#endif /* __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_FRAME_MANIPULATION_IMPL_H__ */
