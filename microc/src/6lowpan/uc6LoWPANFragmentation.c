/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANFragmentation.h>
#include <base/ucError.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>

enum
{
    WHIP6_LOWPAN_MAX_PACKET_LENGTH = WHIP6_IPV6_MIN_MTU,
};


/**
 * Packs the first fragment of the IPv6 packet
 * associated with a given token to a
 * given frame without using any compression.
 * @param token The token associated with
 *   the IPv6 packet.
 * @param frameInfo The frame into which
 *   the fragment will be packed.
 * @return WHIP6_NO_ERROR on success (in which
 *   the payload length of the frame and the
 *   fragmentation offset are modified) or
 *   an error code otherwise (in which case
 *   the fragmentation state is not modified).
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX whip6_error_t whip6_lowpanFragmenterPackFirstFragmentWithRawIpv6Header(
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frameInfo
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *         payloadPtr;
    ieee154_frame_length_t                payloadLen;
    ieee154_frame_length_t                tmp;
    lowpan_header_frag_dgram_size_t       maxFragSize;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo);
    payloadLen = whip6_ieee154DFrameMaxPayloadLen(frameInfo);
    tmp = token->lowpanHdrs->nextOffset;
    if (payloadLen <= tmp)
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    payloadPtr += tmp;
    payloadLen -= tmp;
    *payloadPtr = LOWPAN_DISPATCH_PATTERN_IPV6;
    ++payloadPtr;
    --payloadLen;
    maxFragSize =
            whip6_ipv6BasicHeaderGetPayloadLength(&token->packet->header) +
                    sizeof(ipv6_basic_header_t);
    if (maxFragSize < (lowpan_header_frag_dgram_size_t)payloadLen)
    {
        payloadLen = (ieee154_frame_length_t)maxFragSize;
    }
    else
    {
        payloadLen &= ~(ieee154_frame_length_t)0x07;
    }
    if (payloadLen == 0)
    {
        return WHIP6_SIZE_ERROR;
    }
    if (sizeof(ipv6_basic_header_t) >= payloadLen)
    {
        whip6_shortMemCpy(
                (uint8_t *)(&token->packet->header),
                payloadPtr,
                payloadLen
        );
        payloadPtr += payloadLen;
        token->fragOffset = payloadLen;
    }
    else
    {
        whip6_shortMemCpy(
                (uint8_t *)(&token->packet->header),
                payloadPtr,
                sizeof(ipv6_basic_header_t)
        );
        payloadPtr += sizeof(ipv6_basic_header_t);
        payloadLen -= sizeof(ipv6_basic_header_t);
        token->fragOffset = sizeof(ipv6_basic_header_t);
        tmp =
                whip6_iovShortRead(
                        token->packet->firstPayloadIov,
                        0,
                        payloadPtr,
                        payloadLen
                );
        payloadPtr += tmp;
        token->fragOffset += tmp;
    }
    whip6_ieee154DFrameSetPayloadLen(
            frameInfo,
            (ieee154_frame_length_t)(
                    payloadPtr -
                            whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo))
    );
    return WHIP6_NO_ERROR;
}



/**
 * Packs the first fragment of the IPv6 packet
 * associated with a given token to a
 * given frame.
 * @param token The token associated with
 *   the IPv6 packet.
 * @param frameInfo The frame into which
 *   the fragment will be packed.
 * @param fragFlags The fragmentation flags.
 * @return WHIP6_NO_ERROR on success (in which
 *   the payload length of the frame and the
 *   fragmentation offset are modified) or
 *   an error code otherwise (in which case
 *   the fragmentation state is not modified).
 */
WHIP6_MICROC_INLINE_DEF_PREFIX whip6_error_t whip6_lowpanFragmenterPackFirstFragment(
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frameInfo,
        uint8_t fragFlags
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if ((fragFlags & LOWPAN_WHIP6_USE_IPHC) != 0)
    {
        return WHIP6_STATE_ERROR;
    }
    else
    {
        return whip6_lowpanFragmenterPackFirstFragmentWithRawIpv6Header(
                token,
                frameInfo
        );
    }
}



/**
 * Packs a nonfirst fragment of the IPv6 packet
 * associated with a given token to a
 * given frame.
 * @param token The token associated with
 *   the IPv6 packet.
 * @param frameInfo The frame into which
 *   the fragment will be packed.
 * @return WHIP6_NO_ERROR on success (in which
 *   the payload length of the frame and the
 *   fragmentation offset are modified) or
 *   an error code otherwise (in which case
 *   the fragmentation state is not modified).
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX whip6_error_t whip6_lowpanFragmenterPackSubsequentFragment(
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frameInfo
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *         payloadPtr;
    ieee154_frame_length_t                payloadLen;
    ieee154_frame_length_t                tmp;
    lowpan_header_frag_dgram_size_t       maxFragSize;

    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo);
    payloadLen = whip6_ieee154DFrameMaxPayloadLen(frameInfo);
    tmp = token->lowpanHdrs->nextOffset;
    if (payloadLen <= tmp)
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    payloadPtr += tmp;
    payloadLen -= tmp;
    maxFragSize =
            whip6_ipv6BasicHeaderGetPayloadLength(&token->packet->header) +
                    sizeof(ipv6_basic_header_t) - token->fragOffset;
    if (maxFragSize < (lowpan_header_frag_dgram_size_t)payloadLen)
    {
        payloadLen = (ieee154_frame_length_t)maxFragSize;
    }
    else
    {
        payloadLen &= ~(ieee154_frame_length_t)0x07;
    }
    if (payloadLen == 0)
    {
        return WHIP6_SIZE_ERROR;
    }
    if (token->fragOffset < sizeof(ipv6_basic_header_t))
    {
        maxFragSize = sizeof(ipv6_basic_header_t) - token->fragOffset;
        tmp = payloadLen;
        if (maxFragSize < (lowpan_header_frag_dgram_size_t)tmp)
        {
            tmp = (ieee154_frame_length_t)maxFragSize;
        }
        whip6_shortMemCpy(
                (uint8_t *)(&token->packet->header) + token->fragOffset,
                payloadPtr,
                tmp
        );
        payloadPtr += tmp;
        payloadLen -= tmp;
        token->fragOffset += tmp;
    }
    if (payloadLen > 0)
    {
        whip6_iovShortRead(
                token->packet->firstPayloadIov,
                token->fragOffset - sizeof(ipv6_basic_header_t),
                payloadPtr,
                payloadLen
        );
        payloadPtr += payloadLen;
        token->fragOffset += payloadLen;
    }
    whip6_ieee154DFrameSetPayloadLen(
            frameInfo,
            (ieee154_frame_length_t)(
                    payloadPtr -
                            whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo))
    );
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanFragmenterInit(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * pktsArrPtr,
        uint8_t pktsArrLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    state->currentPackets = NULL;
    if (pktsArrLen > 0 && pktsArrPtr != NULL)
    {
        state->freePackets = pktsArrPtr;
        --pktsArrLen;
        while (pktsArrLen > 0)
        {
            lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * tmp = pktsArrPtr;
            ++pktsArrPtr;
            tmp->next = pktsArrPtr;
            --pktsArrLen;
        }
        pktsArrPtr->next = NULL;
    }
    else
    {
        state->freePackets = NULL;
    }
    // NOTICE iwanicki 2013-03-23:
    // The tag generator should perhaps be persistent.
    // However, we do not care about a possible packet
    // mess-up, because the mess-up will likely be
    // detected with a CRC at a higher level.
    state->tagGenerator = 0;
    state->fragFlags = 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * whip6_lowpanFragmenterStartFragmentingIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   token;
    ipv6_payload_length_t                              packetLen;

    token = state->freePackets;
    if (token == NULL)
    {
        return NULL;
    }
    packetLen = whip6_ipv6BasicHeaderGetPayloadLength(&packet->header);
    if (packetLen > WHIP6_LOWPAN_MAX_PACKET_LENGTH - sizeof(ipv6_basic_header_t))
    {
        return NULL;
    }
    // NOTICE iwanicki 2013-05-08:
    // We may have packets with empty payloads.
//    if (packet->firstPayloadIov == NULL)
//    {
//        return NULL;
//    }
    if (packetLen > whip6_iovGetTotalLength(packet->firstPayloadIov))
    {
        return NULL;
    }
    state->freePackets = token->next;
    token->next = state->currentPackets;
    token->packet = packet;
    token->lowpanHdrs = NULL;
    token->fragOffset = 0;
    token->fragTag = state->tagGenerator;
    ++state->tagGenerator;
    state->currentPackets = token;
    return token;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanFragmenterProvideAdditional6LoWPANHeadersForIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * lowpanHdrs
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    // NOTICE iwanicki 2013-03-22:
    // For performance reasons, we will
    // perform only minimal checks. If
    // all checks are necessary, uncomment
    // the commented code.

    // === START OF CHECK CODE ===
    /*lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   currToken;

    currToken = state->currentPackets;
    while (currToken != NULL && currToken != token)
    {
        currToken = currToken->next;
    }
    if (currToken == NULL)
    {
        return WHIP6_STATE_ERROR;
    }*/
    // === END OF CHECK CODE ===

    (void)state;
    token->lowpanHdrs = lowpanHdrs;
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanFragmenterRequestNextFragmentOfIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM * frameInfo
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    // NOTICE iwanicki 2013-03-22:
    // For performance reasons, we will
    // perform only minimal checks. If
    // all checks are necessary, uncomment
    // the commented code.

    // === START OF CHECK CODE ===
    /*lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   currToken;

    currToken = state->currentPackets;
    while (currToken != NULL && currToken != token)
    {
        currToken = currToken->next;
    }
    if (currToken == NULL)
    {
        return WHIP6_STATE_ERROR;
    }*/
    // === END OF CHECK CODE ===

    // Check if we have the 6LoWPAN headers.
    if (token->lowpanHdrs == NULL)
    {
        return WHIP6_STATE_ERROR;
    }
    // Add a fragmentation headers and pack everything.
    whip6_lowpanFrameHeadersAddFragHeader(
            token->lowpanHdrs,
            token->fragTag,
            whip6_ipv6BasicHeaderGetPayloadLength(&token->packet->header) +
                    sizeof(ipv6_basic_header_t),
            token->fragOffset
    );
    if (whip6_lowpanFrameHeadersPack(token->lowpanHdrs, frameInfo) != WHIP6_NO_ERROR)
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    // Check which fragment we are dealing with.
    return token->fragOffset == 0 ?
            whip6_lowpanFragmenterPackFirstFragment(token, frameInfo, state->fragFlags) :
            whip6_lowpanFragmenterPackSubsequentFragment(token, frameInfo);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanFragmenterFinishFragmentingIpv6Packet(
        lowpan_frag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_frag_packet_state_t MCS51_STORED_IN_RAM * token
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   prevToken;
    lowpan_frag_packet_state_t MCS51_STORED_IN_RAM *   currToken;
    ipv6_packet_t MCS51_STORED_IN_RAM *                packet;

    prevToken = NULL;
    currToken = state->currentPackets;
    while (currToken != NULL && currToken != token)
    {
        prevToken = currToken;
        currToken = currToken->next;
    }
    if (currToken == NULL)
    {
        return NULL;
    }
    if (prevToken == NULL)
    {
        state->currentPackets = currToken->next;
    }
    else
    {
        prevToken->next = currToken->next;
    }
    currToken->next = state->freePackets;
    state->freePackets = currToken;
    packet = currToken->packet;
    currToken->packet = NULL;
    currToken->lowpanHdrs = NULL;
    return packet;
}
