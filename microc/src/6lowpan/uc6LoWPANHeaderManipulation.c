/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>



/**
 * Unpacks a mesh header from a frame.
 * @param hdr The header to be unpacked.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   deserialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackMeshHdr(
        lowpan_unpacked_header_mesh_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


/**
 * Packs a mesh header into a frame.
 * @param hdr The header to be packed.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   serialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersPackMeshHdr(
        lowpan_unpacked_header_mesh_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


/**
 * Unpacks a broadcast 0 header from a frame.
 * @param hdr The header to be unpacked.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   deserialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackBc0Hdr(
        lowpan_unpacked_header_bc0_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


/**
 * Packs a broadcast 0 header into a frame.
 * @param hdr The header to be packed.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   serialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersPackBc0Hdr(
        lowpan_unpacked_header_bc0_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


/**
 * Unpacks a fragmentation header from a frame.
 * @param hdr The header to be unpacked.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   deserialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackFragxHdr(
        lowpan_unpacked_header_frag_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;


/**
 * Packs a fragmentation header into a frame.
 * @param hdr The header to be packed.
 * @param payloadPtr A pointer to the
 *   payload buffer.
 * @param globalOffset An offset at which
 *   serialization should start.
 * @param globalLimit The maximal value of
 *   the offset.
 * @return The size of the serialized header,
 *   or zero denoting an error.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersPackFragxHdr(
        lowpan_unpacked_header_frag_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;





// =========================================================================
// =                                                                       =
// =                       I M P L E M E N T A T I O N                     =
// =                                                                       =
// =========================================================================

WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanFrameHeadersUnpack(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const * payloadPtr;
    ieee154_frame_length_t              payloadLen;
    uint8_t                             currentOffset;
    uint8_t                             headerSize;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frame);
    payloadLen = whip6_ieee154DFrameGetPayloadLen(frame);
    hdrs->bitmap = 0;
    hdrs->nextOffset = 0;
    currentOffset = 0;
    while (currentOffset < payloadLen)
    {
        uint8_t dispatch = payloadPtr[currentOffset];
        if ((dispatch & LOWPAN_DISPATCH_MASK_LOWPAN_IPHC) ==
                LOWPAN_DISPATCH_PATTERN_LOWPAN_IPHC)
        {
            // An IPHC header, so we can stop processing.
            hdrs->nextOffset = currentOffset;
            return WHIP6_NO_ERROR;
        }
        else if ((dispatch & LOWPAN_DISPATCH_MASK_IPV6) ==
                LOWPAN_DISPATCH_PATTERN_IPV6)
        {
            // A raw IPv6 header, so we can stop processing.
            hdrs->nextOffset = currentOffset;
            return WHIP6_NO_ERROR;
        }
        else if ((dispatch & LOWPAN_DISPATCH_MASK_FRAGX) ==
                LOWPAN_DISPATCH_PATTERN_FRAGX)
        {
            // Either a FRAG1 or a FRAGN header,
            // so we have to parse it.
            if ((hdrs->bitmap & LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT) != 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT;
            headerSize =
                    whip6_lowpanFrameHeadersUnpackFragxHdr(
                            &hdrs->frag,
                            payloadPtr,
                            currentOffset,
                            payloadLen
                    );
            if (headerSize == 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            currentOffset += headerSize;
            if (hdrs->frag.offset > 0)
            {
                hdrs->nextOffset = currentOffset;
                return WHIP6_NO_ERROR;
            }
        }
        else if ((dispatch & LOWPAN_DISPATCH_MASK_MESH) ==
                LOWPAN_DISPATCH_PATTERN_MESH)
        {
            // This is a mesh routing header.
            if ((hdrs->bitmap & (LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT | LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT | LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT)) != 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT;
            headerSize =
                    whip6_lowpanFrameHeadersUnpackMeshHdr(
                            &hdrs->mesh,
                            payloadPtr,
                            currentOffset,
                            payloadLen
                    );
            if (headerSize == 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            currentOffset += headerSize;
        }
        else if ((dispatch & LOWPAN_DISPATCH_MASK_LOWPAN_BC0) ==
                LOWPAN_DISPATCH_PATTERN_LOWPAN_BC0)
        {
            // This is a broadcast 0 header.
            if ((hdrs->bitmap & (LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT | LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT)) != 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            hdrs->bitmap |= LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT;
            headerSize =
                    whip6_lowpanFrameHeadersUnpackBc0Hdr(
                            &hdrs->bc0,
                            payloadPtr,
                            currentOffset,
                            payloadLen
                    );
            if (headerSize == 0)
            {
                goto FAILURE_FALLBACK_0;
            }
            currentOffset += headerSize;
        }
        else
        {
            // This is an unrecognized header.
            goto FAILURE_FALLBACK_0;
        }
    }
FAILURE_FALLBACK_0:
    hdrs->bitmap = 0;
    hdrs->nextOffset = 0;
    return WHIP6_ARGUMENT_ERROR;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackMeshHdr(
        lowpan_unpacked_header_mesh_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t   currentOffset = initialOffset;
    uint8_t   dispatch = payloadPtr[currentOffset];

    ++currentOffset;
    hdr->hopLimit = dispatch & 0x0f;
    if (hdr->hopLimit == 0x0f)
    {
        if (currentOffset >= payloadLen)
        {
            return 0;
        }
        hdr->hopLimit = payloadPtr[currentOffset];
        ++currentOffset;
    }
    if ((dispatch & 0x20) != 0)
    {
        if (currentOffset + IEEE154_EXT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        hdr->srcAddr.mode = IEEE154_ADDR_MODE_EXT;
        whip6_ieee154AddrExtCpy(
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM const *)&(payloadPtr[currentOffset]),
                &hdr->srcAddr.vars.ext
        );
        currentOffset += IEEE154_EXT_ADDR_BYTE_LENGTH;
    }
    else
    {
        if (currentOffset + IEEE154_SHORT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        hdr->srcAddr.mode = IEEE154_ADDR_MODE_SHORT;
        whip6_ieee154AddrShortCpy(
                (ieee154_short_addr_t MCS51_STORED_IN_RAM const *)&(payloadPtr[currentOffset]),
                &hdr->srcAddr.vars.shrt
        );
        currentOffset += IEEE154_SHORT_ADDR_BYTE_LENGTH;
    }
    if ((dispatch & 0x10) != 0)
    {
        if (currentOffset + IEEE154_EXT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        hdr->dstAddr.mode = IEEE154_ADDR_MODE_EXT;
        whip6_ieee154AddrExtCpy(
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM const *)&(payloadPtr[currentOffset]),
                &hdr->dstAddr.vars.ext
        );
        currentOffset += IEEE154_EXT_ADDR_BYTE_LENGTH;
    }
    else
    {
        if (currentOffset + IEEE154_SHORT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        hdr->dstAddr.mode = IEEE154_ADDR_MODE_SHORT;
        whip6_ieee154AddrShortCpy(
                (ieee154_short_addr_t MCS51_STORED_IN_RAM const *)&(payloadPtr[currentOffset]),
                &hdr->dstAddr.vars.shrt
        );
        currentOffset += IEEE154_SHORT_ADDR_BYTE_LENGTH;
    }
    return currentOffset - initialOffset;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackBc0Hdr(
        lowpan_unpacked_header_bc0_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ++initialOffset;
    if (initialOffset >= payloadLen)
    {
        return 0;
    }
    hdr->seqNo = payloadPtr[initialOffset];
    return 2;
}



WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_lowpanFrameHeadersUnpackFragxHdr(
        lowpan_unpacked_header_frag_t MCS51_STORED_IN_RAM * hdr,
        uint8_t MCS51_STORED_IN_RAM const * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX
{
    uint8_t    currentOffset = initialOffset;
    uint8_t    dispatch = payloadPtr[currentOffset];
    uint16_t   tmp;

    ++currentOffset;
    if (currentOffset + 3 > payloadLen)
    {
        return 0;
    }
    tmp = dispatch & (uint8_t)(~LOWPAN_DISPATCH_MASK_FRAGX_UNMASKED);
    tmp = tmp << 8;
    tmp |= payloadPtr[currentOffset];
    ++currentOffset;
    hdr->size = tmp;
    tmp = payloadPtr[currentOffset];
    tmp = tmp << 8;
    ++currentOffset;
    tmp |= payloadPtr[currentOffset];
    ++currentOffset;
    hdr->tag = tmp;
    if ((dispatch & LOWPAN_DISPATCH_MASK_FRAGN) ==
                    LOWPAN_DISPATCH_PATTERN_FRAGN)
    {
        // For a FRAGN header, we have to parse the offset.
        if (currentOffset >= payloadLen)
        {
            return 0;
        }
        tmp = payloadPtr[currentOffset];
        tmp = tmp << 3;
        ++currentOffset;
        hdr->offset = tmp;
    }
    else
    {
        // For a FRAG1 header, we just zero the offset.
        hdr->offset = 0;
    }
    return currentOffset - initialOffset;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanFrameHeadersPack(
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * hdrs,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frame
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM * payloadPtr;
    ieee154_frame_length_t        payloadLen;
    ieee154_frame_length_t        payloadOff;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frame);
    payloadLen = whip6_ieee154DFrameMaxPayloadLen(frame);
    payloadOff = 0;
    if ((hdrs->bitmap & LOWPAN_WHIP6_INTERNAL_MESH_HEADER_BIT) != 0)
    {
        // The mesh routing header has to be serialized.
        uint8_t headerSize;
        headerSize =
                whip6_lowpanFrameHeadersPackMeshHdr(
                        &hdrs->mesh,
                        payloadPtr,
                        payloadOff,
                        payloadLen
                );
        if (headerSize == 0)
        {
            return WHIP6_ARGUMENT_ERROR;
        }
        payloadOff += headerSize;
    }
    if ((hdrs->bitmap & LOWPAN_WHIP6_INTERNAL_BC0_HEADER_BIT) != 0)
    {
        // The broadcast 0 header has to be serialized.
        uint8_t headerSize;
        headerSize =
                whip6_lowpanFrameHeadersPackBc0Hdr(
                        &hdrs->bc0,
                        payloadPtr,
                        payloadOff,
                        payloadLen
                );
        if (headerSize == 0)
        {
            return WHIP6_ARGUMENT_ERROR;
        }
        payloadOff += headerSize;
    }
    if ((hdrs->bitmap & LOWPAN_WHIP6_INTERNAL_FRAGX_HEADER_BIT) != 0)
    {
        // One of the fragment headers has to be serialized.
        uint8_t headerSize;
        headerSize =
                whip6_lowpanFrameHeadersPackFragxHdr(
                        &hdrs->frag,
                        payloadPtr,
                        payloadOff,
                        payloadLen
                );
        if (headerSize == 0)
        {
            return WHIP6_ARGUMENT_ERROR;
        }
        payloadOff += headerSize;
    }
    hdrs->nextOffset = payloadOff;
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanFrameHeadersPackMeshHdr(
        lowpan_unpacked_header_mesh_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t   dispatch = LOWPAN_DISPATCH_PATTERN_MESH;
    uint8_t   currentOffset = initialOffset + 1;
    if (currentOffset > payloadLen)
    {
        return 0;
    }
    if (hdr->hopLimit < 0x0f)
    {
        dispatch |= hdr->hopLimit;
    }
    else
    {
        dispatch |= 0x0f;
        if (currentOffset >= payloadLen)
        {
            return 0;
        }
        payloadPtr[currentOffset] = hdr->hopLimit;
        ++currentOffset;
    }
    if (hdr->srcAddr.mode == IEEE154_ADDR_MODE_EXT)
    {
        dispatch |= 0x20;
        if (currentOffset + IEEE154_EXT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        whip6_ieee154AddrExtCpy(
                &(hdr->srcAddr.vars.ext),
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM *)&(payloadPtr[currentOffset])
        );
        currentOffset += IEEE154_EXT_ADDR_BYTE_LENGTH;
    }
    else if (hdr->srcAddr.mode == IEEE154_ADDR_MODE_SHORT)
    {
        if (currentOffset + IEEE154_SHORT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        whip6_ieee154AddrShortCpy(
                &(hdr->srcAddr.vars.shrt),
                (ieee154_short_addr_t MCS51_STORED_IN_RAM *)&(payloadPtr[currentOffset])
        );
        currentOffset += IEEE154_SHORT_ADDR_BYTE_LENGTH;
    }
    else
    {
        return 0;
    }
    if (hdr->dstAddr.mode == IEEE154_ADDR_MODE_EXT)
    {
        dispatch |= 0x10;
        if (currentOffset + IEEE154_EXT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        whip6_ieee154AddrExtCpy(
                &hdr->dstAddr.vars.ext,
                (ieee154_ext_addr_t MCS51_STORED_IN_RAM *)&(payloadPtr[currentOffset])
        );
        currentOffset += IEEE154_EXT_ADDR_BYTE_LENGTH;
    }
    else if (hdr->dstAddr.mode == IEEE154_ADDR_MODE_SHORT)
    {
        if (currentOffset + IEEE154_SHORT_ADDR_BYTE_LENGTH > payloadLen)
        {
            return 0;
        }
        whip6_ieee154AddrShortCpy(
                &hdr->dstAddr.vars.shrt,
                (ieee154_short_addr_t MCS51_STORED_IN_RAM *)&(payloadPtr[currentOffset])
        );
        currentOffset += IEEE154_SHORT_ADDR_BYTE_LENGTH;
    }
    else
    {
        return 0;
    }
    payloadPtr[initialOffset] = dispatch;
    return currentOffset - initialOffset;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanFrameHeadersPackBc0Hdr(
        lowpan_unpacked_header_bc0_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if (initialOffset + 2 > payloadLen)
    {
        return 0;
    }
    payloadPtr[initialOffset] = LOWPAN_DISPATCH_PATTERN_LOWPAN_BC0;
    ++initialOffset;
    payloadPtr[initialOffset] = hdr->seqNo;
    ++initialOffset;
    return 2;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanFrameHeadersPackFragxHdr(
        lowpan_unpacked_header_frag_t MCS51_STORED_IN_RAM const * hdr,
        uint8_t MCS51_STORED_IN_RAM * payloadPtr,
        uint8_t initialOffset,
        uint8_t payloadLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t   dispatch;
    uint8_t   currentOffset = initialOffset + 1;
    if (currentOffset + 3 > payloadLen)
    {
        return 0;
    }
    dispatch =
            (uint8_t)(hdr->size >> 8) &
                    (uint8_t)(~LOWPAN_DISPATCH_MASK_FRAGX_UNMASKED);
    payloadPtr[currentOffset] = (uint8_t)(hdr->size);
    ++currentOffset;
    payloadPtr[currentOffset] = (uint8_t)(hdr->tag >> 8);
    ++currentOffset;
    payloadPtr[currentOffset] = (uint8_t)(hdr->tag);
    ++currentOffset;
    if (hdr->offset > 0)
    {
        if ((hdr->offset & 0x07) != 0 || currentOffset >= payloadLen)
        {
            return 0;
        }
        payloadPtr[currentOffset] = (uint8_t)(hdr->offset >> 3);
        ++currentOffset;
        dispatch |= LOWPAN_DISPATCH_PATTERN_FRAGN;
    }
    else
    {
        dispatch |= LOWPAN_DISPATCH_PATTERN_FRAG1;
    }
    payloadPtr[initialOffset] = dispatch;
    return currentOffset - initialOffset;
}
