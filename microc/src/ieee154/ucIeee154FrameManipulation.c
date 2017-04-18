/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucError.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>


/**
 * Frame control field values.
 */
enum
{
    IEEE154_FCF_FRAME_TYPE_FIELD_OFFSET = 0,
    IEEE154_FCF_FRAME_TYPE_FIELD_LENGTH = 3,
    IEEE154_FCF_FRAME_TYPE_FIELD_MASK = ((1 << IEEE154_FCF_FRAME_TYPE_FIELD_LENGTH) - 1),
    IEEE154_FCF_SECURITY_ENABLED_FLAG_OFFSET = 3,
    IEEE154_FCF_SECURITY_ENABLED_FLAG_BIT = (1 << IEEE154_FCF_SECURITY_ENABLED_FLAG_OFFSET),
    IEEE154_FCF_FRAME_PENDING_FLAG_OFFSET = 4,
    IEEE154_FCF_FRAME_PENDING_FLAG_BIT = (1 << IEEE154_FCF_FRAME_PENDING_FLAG_OFFSET),
    IEEE154_FCF_ACK_REQUEST_FLAG_OFFSET = 5,
    IEEE154_FCF_ACK_REQUEST_FLAG_BIT = (1 << IEEE154_FCF_ACK_REQUEST_FLAG_OFFSET),
    IEEE154_FCF_INTRA_PAN_FLAG_OFFSET = 6,
    IEEE154_FCF_INTRA_PAN_FLAG_BIT = (1 << IEEE154_FCF_INTRA_PAN_FLAG_OFFSET),
    IEEE154_FCF_DST_ADDR_MODE_FIELD_OFFSET = 10,
    IEEE154_FCF_DST_ADDR_MODE_FIELD_LENGTH = 2,
    IEEE154_FCF_DST_ADDR_MODE_FIELD_MASK = ((1 << IEEE154_FCF_DST_ADDR_MODE_FIELD_LENGTH) - 1),
    IEEE154_FCF_SRC_ADDR_MODE_FIELD_OFFSET = 14,
    IEEE154_FCF_SRC_ADDR_MODE_FIELD_LENGTH = 2,
    IEEE154_FCF_SRC_ADDR_MODE_FIELD_MASK = ((1 << IEEE154_FCF_SRC_ADDR_MODE_FIELD_LENGTH) - 1),
};

/**
 * Sets the Acknowledge request bit in the FCF.
 * @param frame The frame for which the bit is to be set.
 */
WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ieee154DFrameSetFCFACKRequest(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX {
    frame->bufferPtr[1] |= IEEE154_FCF_ACK_REQUEST_FLAG_BIT;
}

WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_ieee154DFrameInfoNew(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen,
        uint8_t flags
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t currOff;
    if (bufLen < IEEE154_DFRAME_MINIMAL_SIZE)
    {
        return WHIP6_SIZE_ERROR;
    }
    frame->bufferPtr = bufPtr;
    frame->bufferLen = bufLen;
    frame->frameFlags = flags;
    frame->payloadAndDstAddrOff = 0;
    frame->srcPanAndAddrOff = 0;
    // Initialize the FCF to default values.
    bufPtr[1] = (IEEE154_DFRAME_TYPE << IEEE154_FCF_FRAME_TYPE_FIELD_OFFSET);
    bufPtr[2] = 0;
    currOff = 0;
    // Set the destination addressing mode in the FCF.
    switch ((flags >> IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)
    {
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
        return WHIP6_ARGUMENT_ERROR;
    case IEEE154_ADDR_MODE_SHORT:
        frame->payloadAndDstAddrOff = currOff + IEEE154_PAN_ID_BYTE_LENGTH;
        currOff += IEEE154_PAN_ID_BYTE_LENGTH + IEEE154_SHORT_ADDR_BYTE_LENGTH;
        bufPtr[2] |= (IEEE154_ADDR_MODE_SHORT << (IEEE154_FCF_DST_ADDR_MODE_FIELD_OFFSET - 8));
        break;
    case IEEE154_ADDR_MODE_EXT:
        frame->payloadAndDstAddrOff = currOff + IEEE154_PAN_ID_BYTE_LENGTH;
        currOff += IEEE154_PAN_ID_BYTE_LENGTH + IEEE154_EXT_ADDR_BYTE_LENGTH;
        bufPtr[2] |= (IEEE154_ADDR_MODE_EXT << (IEEE154_FCF_DST_ADDR_MODE_FIELD_OFFSET - 8));
        break;
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    // Set the source PAN id in the FCF.
    frame->srcPanAndAddrOff = (currOff << 4);
    if ((flags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) != 0)
    {
        currOff += IEEE154_PAN_ID_BYTE_LENGTH;
    }
    else
    {
        bufPtr[1] |= IEEE154_FCF_INTRA_PAN_FLAG_BIT;
    }
    // Set the source addressing mode in the FCF.
    switch ((flags >> IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)
    {
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
        return WHIP6_ARGUMENT_ERROR;
    case IEEE154_ADDR_MODE_SHORT:
        frame->srcPanAndAddrOff |= currOff;
        currOff += IEEE154_SHORT_ADDR_BYTE_LENGTH;
        bufPtr[2] |= (IEEE154_ADDR_MODE_SHORT << (IEEE154_FCF_SRC_ADDR_MODE_FIELD_OFFSET - 8));
        break;
    case IEEE154_ADDR_MODE_EXT:
        frame->srcPanAndAddrOff |= currOff;
        currOff += IEEE154_EXT_ADDR_BYTE_LENGTH;
        bufPtr[2] |= (IEEE154_ADDR_MODE_EXT << (IEEE154_FCF_SRC_ADDR_MODE_FIELD_OFFSET - 8));
        break;
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    // Set the payload offset.
    bufPtr[0] = currOff + (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE - 1);
    if (bufLen < bufPtr[0] + 1)
    {
        // The size of the input buffer is invalid.
        return WHIP6_SIZE_ERROR;
    }
    frame->payloadAndDstAddrOff |= (currOff << 3);
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_ieee154DFrameInfoReinitializeFrameForAddresses(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * dstPanId,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * srcPanIdOrNull
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ieee154_dframe_info_t   frameInfoCopy;
    whip6_error_t           status;
    uint8_t                 flags;

    if (frame->bufferPtr == NULL || frame->bufferLen == 0)
    {
        return WHIP6_STATE_ERROR;
    }
    frameInfoCopy.bufferPtr = frame->bufferPtr;
    frameInfoCopy.bufferLen = frame->bufferLen;
    frameInfoCopy.frameFlags = frame->frameFlags;
    frameInfoCopy.payloadAndDstAddrOff = frame->payloadAndDstAddrOff;
    frameInfoCopy.srcPanAndAddrOff = frame->srcPanAndAddrOff;
    flags = 0;
    flags |= (dstAddr->mode & IEEE154_ADDR_MODE_MASK) << IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT;
    flags |= (srcAddr->mode & IEEE154_ADDR_MODE_MASK) << IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT;
    if (srcPanIdOrNull != NULL)
    {
        flags |= IEEE154_DFRAME_INFO_FLAG_INTER_PAN;
    }
    status = whip6_ieee154DFrameInfoNew(frame, frame->bufferPtr, frame->bufferLen, flags);
    if (status != WHIP6_NO_ERROR)
    {
        goto FAILURE_ROLLBACK;
    }
    whip6_ieee154DFrameSetSeqNo(frame, 0);
    whip6_ieee154DFrameSetSrcAddr(frame, srcAddr);
    whip6_ieee154DFrameSetDstAddr(frame, dstAddr);
    whip6_ieee154DFrameSetDstPanId(frame, dstPanId);
    if (whip6_ieee154DFrameIsInterPan(frame))
    {
        whip6_ieee154DFrameSetSrcPanId(frame, srcPanIdOrNull);
    }
    return WHIP6_NO_ERROR;

FAILURE_ROLLBACK:
    frame->bufferPtr = frameInfoCopy.bufferPtr;
    frame->bufferLen = frameInfoCopy.bufferLen;
    frame->frameFlags = frameInfoCopy.frameFlags;
    frame->payloadAndDstAddrOff = frameInfoCopy.payloadAndDstAddrOff;
    frame->srcPanAndAddrOff = frameInfoCopy.srcPanAndAddrOff;
    return status;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_ieee154DFrameInfoReinitializeFrameInOppositeDirection(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * outFrame,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * inFrame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   inPtr;
    uint8_t MCS51_STORED_IN_RAM *         outPtr;
    uint8_t const                         inFlags = inFrame->frameFlags;
    uint8_t                               outFlags;
    uint8_t                               off;
    uint8_t                               cnt;

    if (outFrame->bufferPtr == NULL || outFrame->bufferLen <
            (inFrame->payloadAndDstAddrOff >> 3) + (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE))
    {
        return WHIP6_STATE_ERROR;
    }
    inPtr = &(inFrame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
    outPtr = &(outFrame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
    outFlags = 0;
    off = 0;
    if ((inFlags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) != 0)
    {
        outFlags |= IEEE154_DFRAME_INFO_FLAG_INTER_PAN;
        inPtr += (inFrame->srcPanAndAddrOff >> 4);
    }
    *outPtr = *inPtr;
    ++outPtr;
    ++inPtr;
    *outPtr = *inPtr;
    ++outPtr;
    off += IEEE154_PAN_ID_BYTE_LENGTH;
    outFrame->payloadAndDstAddrOff = (off & 0x7);
    inPtr = &(inFrame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
    inPtr += (inFrame->srcPanAndAddrOff & 0x0f);
    switch ((inFlags >> IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)
    {
    case IEEE154_ADDR_MODE_EXT:
        outFlags |= IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_EXT;
        cnt = IEEE154_EXT_ADDR_BYTE_LENGTH;
        break;
    case IEEE154_ADDR_MODE_SHORT:
        outFlags |= IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHORT;
        cnt = IEEE154_SHORT_ADDR_BYTE_LENGTH;
        break;
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    off += cnt;
    for (; cnt > 0; --cnt)
    {
        *outPtr = *inPtr;
        ++outPtr;
        ++inPtr;
    }
    outFrame->srcPanAndAddrOff = (off << 4);
    if ((inFlags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) != 0)
    {
        inPtr = &(inFrame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
        *outPtr = *inPtr;
        ++outPtr;
        ++inPtr;
        *outPtr = *inPtr;
        ++outPtr;
        off += IEEE154_PAN_ID_BYTE_LENGTH;
    }
    outFrame->srcPanAndAddrOff |= (off & 0x0f);
    inPtr = &(inFrame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
    inPtr += (inFrame->payloadAndDstAddrOff & 0x07);
    switch ((inFlags >> IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHIFT) & IEEE154_ADDR_MODE_MASK)
    {
    case IEEE154_ADDR_MODE_EXT:
        outFlags |= IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_EXT;
        cnt = IEEE154_EXT_ADDR_BYTE_LENGTH;
        break;
    case IEEE154_ADDR_MODE_SHORT:
        outFlags |= IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHORT;
        cnt = IEEE154_SHORT_ADDR_BYTE_LENGTH;
        break;
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    off += cnt;
    for (; cnt > 0; --cnt)
    {
        *outPtr = *inPtr;
        ++outPtr;
        ++inPtr;
    }
    outFrame->payloadAndDstAddrOff |= (off << 3);
    outFrame->frameFlags = outFlags;
    outFrame->bufferPtr[1] = inFrame->bufferPtr[1];
    outFrame->bufferPtr[2] = (inFrame->bufferPtr[2] >> 4) | (inFrame->bufferPtr[2] << 4);
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_ieee154DFrameInfoExisting(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        uint8_t MCS51_STORED_IN_RAM * bufPtr,
        uint8_t bufLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    // NOTICE 2012-12-29:
    // The support for data frames is very limited.
    // We do not support security and pending frames.
    // We also do not support the NONE addressing mode.
    uint8_t currOff;
    uint8_t tmp;
    if (bufLen < IEEE154_DFRAME_MINIMAL_SIZE)
    {
        return WHIP6_SIZE_ERROR;
    }
    frame->bufferPtr = bufPtr;
    frame->bufferLen = bufLen;
    frame->frameFlags = 0;
    frame->payloadAndDstAddrOff = 0;
    frame->srcPanAndAddrOff = 0;
    tmp = bufPtr[1];
    // Check that the frame is a data frame.
    if (((tmp >> IEEE154_FCF_FRAME_TYPE_FIELD_OFFSET) & IEEE154_FCF_FRAME_TYPE_FIELD_MASK) != IEEE154_DFRAME_TYPE)
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    // Check that none of the unsupported
    // functionalities (security, pending frames) is used by the frame.
    if ((tmp & (IEEE154_FCF_SECURITY_ENABLED_FLAG_BIT | IEEE154_FCF_FRAME_PENDING_FLAG_BIT)) != 0)
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    // Check if the frame is sent within a PAN.
    if ((tmp & IEEE154_FCF_INTRA_PAN_FLAG_BIT) == 0)
    {
        frame->frameFlags |= IEEE154_DFRAME_INFO_FLAG_INTER_PAN;
    }
    currOff = 0;
    // Check the destination addressing mode.
    tmp = (bufPtr[2] >> (IEEE154_FCF_DST_ADDR_MODE_FIELD_OFFSET - 8)) & IEEE154_FCF_DST_ADDR_MODE_FIELD_MASK;
    switch (tmp)
    {
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
        return WHIP6_ARGUMENT_ERROR;
    case IEEE154_ADDR_MODE_SHORT:
        frame->payloadAndDstAddrOff = currOff + IEEE154_PAN_ID_BYTE_LENGTH;
        currOff += IEEE154_PAN_ID_BYTE_LENGTH + IEEE154_SHORT_ADDR_BYTE_LENGTH;
        frame->frameFlags |= IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_SHORT;
        break;
    case IEEE154_ADDR_MODE_EXT:
        frame->payloadAndDstAddrOff = currOff + IEEE154_PAN_ID_BYTE_LENGTH;
        currOff += IEEE154_PAN_ID_BYTE_LENGTH + IEEE154_EXT_ADDR_BYTE_LENGTH;
        frame->frameFlags |= IEEE154_DFRAME_INFO_FLAG_DST_ADDR_MODE_EXT;
        break;
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    // Check the source PAN offset.
    frame->srcPanAndAddrOff = (currOff << 4);
    if ((frame->frameFlags & IEEE154_DFRAME_INFO_FLAG_INTER_PAN) != 0)
    {
        currOff += IEEE154_PAN_ID_BYTE_LENGTH;
    }
    // Check the source addressing mode.
    tmp = (bufPtr[2] >> (IEEE154_FCF_SRC_ADDR_MODE_FIELD_OFFSET - 8)) & IEEE154_FCF_SRC_ADDR_MODE_FIELD_MASK;
    switch (tmp)
    {
    case IEEE154_ADDR_MODE_NONE:
        // NOTICE 2012-12-29 iwanicki:
        // We do not handle the NONE addressing mode.
        return WHIP6_ARGUMENT_ERROR;
    case IEEE154_ADDR_MODE_SHORT:
        frame->srcPanAndAddrOff |= currOff;
        currOff += IEEE154_SHORT_ADDR_BYTE_LENGTH;
        frame->frameFlags |= IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_SHORT;
        break;
    case IEEE154_ADDR_MODE_EXT:
        frame->srcPanAndAddrOff |= currOff;
        currOff += IEEE154_EXT_ADDR_BYTE_LENGTH;
        frame->frameFlags |= IEEE154_DFRAME_INFO_FLAG_SRC_ADDR_MODE_EXT;
        break;
    default:
        return WHIP6_ARGUMENT_ERROR;
    }
    // Check the size.
    if (bufPtr[0] < currOff + (IEEE154_DFRAME_INITIAL_OFFSET + IEEE154_DFRAME_CRC_SIZE - 1))
    {
        // The size of the input buffer is invalid.
        return WHIP6_SIZE_ERROR;
    }
    // Set the payload offset.
    frame->payloadAndDstAddrOff |= (currOff << 3);
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ieee154DFrameInfoCheckIfDestinationMatches(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panIdPtrOrNull,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * shrtAddrPtrOrNull,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * extAddrPtrOrNull
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *  ptr1;
    uint8_t MCS51_STORED_IN_RAM const *  ptr2;
    uint8_t const                        dstMode = whip6_ieee154DFrameGetModeDstAddr(frame);
    ieee154_frame_length_t const         dstOff = whip6_ieee154DFrameGetOffsetDstAddr(frame);
    uint8_t                              res;

    if (panIdPtrOrNull != NULL)
    {
        ptr1 = &(frame->bufferPtr[IEEE154_DFRAME_INITIAL_OFFSET]);
        ptr2 = &(panIdPtrOrNull->data[0]);
        res = *ptr1 - *ptr2;
        ++ptr1;
        ++ptr2;
        res |= *ptr1 - *ptr2;
        if (res != 0)
        {
            return 0;
        }
    }
    ptr1 = &(frame->bufferPtr[dstOff]);
    switch (dstMode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        res = *ptr1 - 0xff;
        ++ptr1;
        res |= *ptr1 - 0xff;
        if (res == 0)
        {
            return 1;
        }
        else if (shrtAddrPtrOrNull == NULL)
        {
            return 0;
        }
        --ptr1;
        ptr2 = &(shrtAddrPtrOrNull->data[0]);
        res = *ptr1 - *ptr2;
        ++ptr1;
        ++ptr2;
        res |= *ptr1 - *ptr2;
        return ! res;
    case IEEE154_ADDR_MODE_EXT:
        if (extAddrPtrOrNull == NULL)
        {
            return 0;
        }
        ptr2 = &(extAddrPtrOrNull->data[0]);
        return ! whip6_shortMemCmp(ptr1, ptr2, IEEE154_EXT_ADDR_BYTE_LENGTH);
    }
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ieee154DFrameInfoCheckIfDestinationIsBroadcast(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   ptr;
    uint8_t                               res;

    if (whip6_ieee154DFrameGetModeDstAddr(frame) != IEEE154_ADDR_MODE_SHORT)
    {
        return 0;
    }
    ptr = &(frame->bufferPtr[0]);
    ptr += whip6_ieee154DFrameGetOffsetDstAddr(frame);
    res = *ptr - 0xff;
    ++ptr;
    res |= *ptr - 0xff;
    return ! res;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ieee154DFrameGetSrcAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t const                  srcMode = whip6_ieee154DFrameGetModeSrcAddr(frame);
    ieee154_frame_length_t const   srcOff = whip6_ieee154DFrameGetOffsetSrcAddr(frame);
    addr->mode = srcMode;
    switch (srcMode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        whip6_ieee154AddrShortCpy(
                (ieee154_short_addr_t MCS51_STORED_IN_RAM const *)&(frame->bufferPtr[srcOff]),
                &addr->vars.shrt
        );
        break;
    case IEEE154_ADDR_MODE_EXT:
        whip6_ieee154AddrExtCpy(
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM const *)&(frame->bufferPtr[srcOff]),
                &addr->vars.ext
        );
        break;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ieee154DFrameSetSrcAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t const                  srcMode = whip6_ieee154DFrameGetModeSrcAddr(frame);
    ieee154_frame_length_t const   srcOff = whip6_ieee154DFrameGetOffsetSrcAddr(frame);
    switch (srcMode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        whip6_ieee154AddrShortCpy(
                &addr->vars.shrt,
                (ieee154_short_addr_t MCS51_STORED_IN_RAM *)&(frame->bufferPtr[srcOff])
        );
        break;
    case IEEE154_ADDR_MODE_EXT:
        whip6_ieee154AddrExtCpy(
                &addr->vars.ext,
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM *)&(frame->bufferPtr[srcOff])
        );
        break;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ieee154DFrameGetDstAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t const                  dstMode = whip6_ieee154DFrameGetModeDstAddr(frame);
    ieee154_frame_length_t const   dstOff = whip6_ieee154DFrameGetOffsetDstAddr(frame);
    addr->mode = dstMode;
    switch (dstMode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        whip6_ieee154AddrShortCpy(
                (ieee154_short_addr_t MCS51_STORED_IN_RAM const *)&(frame->bufferPtr[dstOff]),
                &addr->vars.shrt
        );
        break;
    case IEEE154_ADDR_MODE_EXT:
        whip6_ieee154AddrExtCpy(
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM const *)&(frame->bufferPtr[dstOff]),
                &addr->vars.ext
        );
        break;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ieee154DFrameSetDstAddr(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t const                  dstMode = whip6_ieee154DFrameGetModeDstAddr(frame);
    ieee154_frame_length_t const   dstOff = whip6_ieee154DFrameGetOffsetDstAddr(frame);
    switch (dstMode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        whip6_ieee154AddrShortCpy(
                &addr->vars.shrt,
                (ieee154_short_addr_t MCS51_STORED_IN_RAM *)&(frame->bufferPtr[dstOff])
        );
        break;
    case IEEE154_ADDR_MODE_EXT:
        whip6_ieee154AddrExtCpy(
                &addr->vars.ext,
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM *)&(frame->bufferPtr[dstOff])
        );
        break;
    }
}
