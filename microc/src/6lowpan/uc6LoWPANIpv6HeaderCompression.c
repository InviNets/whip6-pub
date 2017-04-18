/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANIpv6HeaderCompression.h>
#include <base/ucIoVec.h>
#include <base/ucString.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX ieee154_frame_length_t whip6_lowpanRawIpv6HeaderUnpack(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * hdrs,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        uint8_t * identicalBufPtrOrNull
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const * payloadPtr;
    ieee154_frame_length_t              payloadLen;
    ieee154_frame_length_t              numBytesInPacket;
    ieee154_frame_length_t              numBytesLeft;
    ieee154_frame_length_t              tmp;
    uint8_t                             identical;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frame);
    payloadLen = whip6_ieee154DFrameGetPayloadLen(frame);
    tmp = hdrs->nextOffset;
    if (tmp >= payloadLen)
    {
        return 0;
    }
    payloadPtr += tmp;
    numBytesInPacket = payloadLen - tmp;
    if (((*payloadPtr) & LOWPAN_DISPATCH_MASK_IPV6) != LOWPAN_DISPATCH_PATTERN_IPV6)
    {
        // This is not a raw IPv6 LoWPAN header.
        return 0;
    }
    ++payloadPtr;
    --numBytesInPacket;
    if ((numBytesInPacket & 0x07) != 0 &&
            whip6_lowpanFrameHeadersHasFragHeader(hdrs) &&
            whip6_lowpanFrameHeadersGetFragHeaderSize(hdrs) > numBytesInPacket)
    {
        // The offset of the next fragment would
        // be indivisible by 8, so this mustn't
        // be a 6LoWPAN raw IPv6 header.
        return 0;
    }
    numBytesLeft = numBytesInPacket;
    tmp = numBytesLeft;
    if (tmp > sizeof(ipv6_basic_header_t))
    {
        tmp = sizeof(ipv6_basic_header_t);
    }
    identical = 1;
    if (identicalBufPtrOrNull != NULL)
    {
        if (whip6_shortMemCmp(
                payloadPtr, (uint8_t MCS51_STORED_IN_RAM *)&packet->header, tmp) != 0)
        {
            identical = 0;
        }
    }
    whip6_shortMemCpy(
            payloadPtr,
            (uint8_t MCS51_STORED_IN_RAM *)&packet->header,
            tmp
    );
    payloadPtr += tmp;
    numBytesLeft -= tmp;
    if (identical && identicalBufPtrOrNull != NULL)
    {
        if (whip6_iovShortCompare(
                packet->firstPayloadIov, 0, payloadPtr, numBytesLeft) != 0)
        {
            identical = 0;
        }
    }
    tmp =
            whip6_iovShortWrite(
                    packet->firstPayloadIov,
                    0,
                    payloadPtr,
                    numBytesLeft
            );
    if (tmp != numBytesLeft)
    {
        return 0;
    }
    if (identicalBufPtrOrNull != NULL)
    {
        *identicalBufPtrOrNull = identical;
    }
    return numBytesInPacket;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ieee154_frame_length_t whip6_lowpanRawIpv6HeaderPack(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * hdrs,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM * payloadPtr;
    ieee154_frame_length_t        payloadLen;
    ieee154_frame_length_t        payloadOff;
    ieee154_frame_length_t        numCopiedBytes;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frame);
    payloadLen = whip6_ieee154DFrameMaxPayloadLen(frame);
    payloadOff = hdrs->nextOffset;
    if (payloadOff >= payloadLen)
    {
        return 0;
    }
    payloadPtr += payloadOff;
    *payloadPtr = LOWPAN_DISPATCH_PATTERN_IPV6;
    ++payloadPtr;
    ++payloadOff;
    payloadLen -= payloadOff;
    if (whip6_lowpanFrameHeadersHasFragHeader(hdrs) &&
            whip6_lowpanFrameHeadersGetFragHeaderSize(hdrs) > payloadLen)
    {
        payloadLen &= ~((uint8_t)0x07);
    }
    if (payloadLen == 0)
    {
        return 0;
    }
    numCopiedBytes = sizeof(ipv6_basic_header_t);
    if (numCopiedBytes > payloadLen)
    {
        numCopiedBytes = payloadLen;
    }
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)&packet->header,
            payloadPtr,
            numCopiedBytes
    );
    payloadPtr += numCopiedBytes;
    payloadLen -= numCopiedBytes;
    numCopiedBytes +=
            whip6_iovShortRead(
                    packet->firstPayloadIov,
                    0,
                    payloadPtr,
                    payloadLen);
    whip6_ieee154DFrameSetPayloadLen(frame, payloadOff + numCopiedBytes);
    return numCopiedBytes;
}
