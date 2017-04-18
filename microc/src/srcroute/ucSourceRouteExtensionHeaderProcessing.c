/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include <icmpv6/ucIcmpv6BasicMessageBuilders.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>
#include <srcroute/ucSourceRouteExtensionHeaderProcessing.h>



/**
 * Checks if an IPv6 packet whose source routing header is
 * being processed is destined for the present node. If
 * the packet is not destined for the present node, it
 * is designated for forwarding. Otherwise, the source
 * routing header of the packet can be processed.
 * @param state The processing state of the IPv6 packet.
 * @return Zero if the packet is destined for the present node
 *   and hence, its source routing header can be processed;
 *   nonzero if the packet has been designated for forwarding.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfPacketShouldBeProcessedLocallyOrDesignateItForForwarding(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Skips the entire source routing header and designates
 * the packet for further processing assuming there are no
 * segments left in the header. If the operation fails,
 * the packet is designated for dropping without any ICMPv6 message.
 * @param state The processing state of the IPv6 packet.
 * @param headerLen The length of the source routing
 *   header excluding the basic length.
 * @return Zero if the packet has been successfully designated
 *   for further processing, or nonzero if the packet has been
 *   designated for dropping.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteSkipAllSegmentsAndDesignatePacketForFurtherProcessing(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_payload_length_t headerLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Checks if an IPv6 packet whose source routing header is
 * being processed contains the right field denoting
 * the source routing method. If it does not, it
 * is designated for dropping with an appropriate ICMPv6
 * message. Otherwise, the source routing header of the packet
 * can continue being processed.
 * @param state The processing state of the IPv6 packet.
 * @return Zero if the source routing method is correct,
 *   and hence, the source routing header can be processed;
 *   nonzero if the packet has been designated for dropping.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfRoutingMethodIsCorrectOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Checks if an IPv6 packet whose source routing header is
 * being processed contains the right number of remaining
 * segments. If it does not, it is designated for dropping
 * with an appropriate ICMPv6 message. Otherwise, the source
 * routing header of the packet can continue being processed.
 * @param state The processing state of the IPv6 packet.
 * @param segmentsLeft The number of segments left.
 * @param segmentsTotal The total number of segments.
 * @return Zero if the number of segments left is correct, and
 *   hence, the source routing header can be processed further;
 *   nonzero if the packet has been designated for dropping.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfNumSegmentsIsCorrectOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentsLeft,
        ipv6_extension_header_srh_segments_left_t segmentsTotal
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Updates the segments left field in a source routing header
 * of an IPv6 packet being processed. If the update fails,
 * the packet is designated for dropping without any ICMPv6
 * message. It is assumed that the packet's iterator points at
 * the first byte of the first segment.
 * @param state The processing state of the IPv6 packet.
 * @param segmentsLeft The new number of segments left.
 * @return Zero if the update was successful, and
 *   hence, the source routing header can be processed further;
 *   nonzero if the packet has been designated for dropping.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteUpdateSegmentsLeftOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentsLeft
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Reads an address in a given segment of a source
 * routing header, checks if the address is correct,
 * and writes it in the place of the destination address
 * in the basic IPv6 packet header. As a result, the iterator
 * is advanced beyond the entire source routing header,
 * and the packet is designated for forwarding. In the case,
 * of an error, the packet is designated for dropping
 * without any ICMPv6 message.
 * @param state The processing state of the IPv6 packet.
 * @param segmentIndex The index of the segment.
 * @param numSegments The total number of segments.
 * @param headerLen The length of the source routing
 *   header excluding the basic length.
 * @return Zero if the packet has been successfully designated
 *   for forwarding, or nonzero if the packet has been
 *   designated for dropping.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteSetSegmentAddrAsDstAddrAndDesignatePacketForForwarding(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentIndex,
        ipv6_extension_header_srh_segments_left_t numSegments,
        ipv6_payload_length_t headerLen
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteFetchHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    size_t numBytes;

    state->flagsAndAction &= ~(uint8_t)WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK;
    numBytes =
            whip6_iovIteratorReadAndMoveForward(
                    &state->iter,
                    (uint8_t MCS51_STORED_IN_RAM *)&state->scratchpad.sourceRouteHdr,
                    sizeof(ipv6_extension_header_srh_t)
            );
    if (numBytes != sizeof(ipv6_extension_header_srh_t) ||
            ! whip6_iovIteratorIsValid(&state->iter) ||
            whip6_ipv6ExtensionHeaderSourceRouteCheckReserved(&state->scratchpad.sourceRouteHdr))
    {
        // NOTICE iwanicki 2013-06-22:
        // In theory, we could send an ICMPv6 parameter
        // problem message with code 0 (erroneous header
        // field encountered), but let's suppress it.
        state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
        state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
        state->scratchpad.icmpv6.packet = NULL;
    }
    else
    {
        state->offset += sizeof(ipv6_extension_header_srh_t);
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteProcessHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_extension_header_srh_t MCS51_STORED_IN_RAM *   srHdr;
    ipv6_payload_length_t                               srHdrLen;
    ipv6_extension_header_srh_segments_left_t           segmentsLeft;

    // NOTICE iwanicki 2013-06-22:
    // It is assumed that the hop limit is
    // decremented and checked before.

    state->flagsAndAction &= ~(uint8_t)WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK;
    if (whip6_ipv6ExtensionHeaderSourceRouteCheckIfPacketShouldBeProcessedLocallyOrDesignateItForForwarding(state) != 0)
    {
        return;
    }
    srHdr = &state->scratchpad.sourceRouteHdr;
    srHdrLen = whip6_ipv6ExtensionHeaderSourceRouteGetHeaderLength(srHdr);
    segmentsLeft = whip6_ipv6ExtensionHeaderSourceRouteGetSegmentsLeft(srHdr);
    if (segmentsLeft == 0)
    {
        // Nothing to process in the header,
        // so continue to the next one.
        whip6_ipv6ExtensionHeaderSourceRouteSkipAllSegmentsAndDesignatePacketForFurtherProcessing(
                state,
                srHdrLen
        );
    }
    else
    {
        // There are still segments to be processed.
        ipv6_extension_header_srh_segments_left_t   numSegments;
        ipv6_extension_header_srh_segments_left_t   segmentIndex;

        // NOTICE iwanicki 2013-06-22:
        // This should be checked only if SegmentsLeft > 0,
        // as per RFC 2460 (p. 12).
        if (whip6_ipv6ExtensionHeaderSourceRouteCheckIfRoutingMethodIsCorrectOrDesignatePacketForDropping(state) != 0)
        {
            return;
        }
        numSegments =
                (srHdrLen -
                        whip6_ipv6ExtensionHeaderSourceRouteGetPad(srHdr) -
                        (16 - whip6_ipv6ExtensionHeaderSourceRouteGetCmprE(srHdr))) /
                (16 - whip6_ipv6ExtensionHeaderSourceRouteGetCmprI(srHdr)) + 1;
        if (whip6_ipv6ExtensionHeaderSourceRouteCheckIfNumSegmentsIsCorrectOrDesignatePacketForDropping(state, segmentsLeft, numSegments) != 0)
        {
            return;
        }
        segmentIndex = numSegments - segmentsLeft;
        if (whip6_ipv6ExtensionHeaderSourceRouteUpdateSegmentsLeftOrDesignatePacketForDropping(state, segmentsLeft - 1) != 0)
        {
            return;
        }
        whip6_ipv6ExtensionHeaderSourceRouteSetSegmentAddrAsDstAddrAndDesignatePacketForForwarding(
                state,
                segmentIndex,
                numSegments,
                srHdrLen
        );
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfPacketShouldBeProcessedLocallyOrDesignateItForForwarding(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if ((state->flagsAndAction & WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_PRESENT_NODE_IS_DESTINATION) != 0)
    {
        return 0;
    }
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_FINISH_PROCESSING_AND_FORWARD_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteSkipAllSegmentsAndDesignatePacketForFurtherProcessing(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_payload_length_t headerLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ipv6_extension_header_srh_t MCS51_STORED_IN_RAM *   srHdr;

    srHdr = &state->scratchpad.sourceRouteHdr;
    if (whip6_iovIteratorMoveForward(&state->iter, headerLen) != headerLen)
    {
        goto FAILURE_ROLLBACK_0;
    }
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_CONTINUE_PROCESSING_PACKET;
    state->nextHeader = whip6_ipv6ExtensionHeaderSourceRouteGetNextHeader(srHdr);
    state->scratchpad.icmpv6.packet = NULL;
    state->scratchpad.icmpv6.nextHdrFieldPointer =
            state->offset - (
                    sizeof(ipv6_extension_header_srh_t) -
                    offsetof(ipv6_extension_header_srh_t, nextHdr));
    state->offset += headerLen;
    return 0;

FAILURE_ROLLBACK_0:
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfRoutingMethodIsCorrectOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ipv6_extension_header_srh_t MCS51_STORED_IN_RAM *   srHdr;

    srHdr = &state->scratchpad.sourceRouteHdr;
    if (whip6_ipv6ExtensionHeaderSourceRouteGetRoutingType(srHdr) ==
            WHIP6_IPV6_EXTENSION_HEADER_SOURCE_ROUTE_SUPPORTED_ROUTING_TYPE)
    {
        return 0;
    }
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    if ((state->flagsAndAction & WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_DISABLE_ICMPV6_ERROR_MESSAGES) == 0)
    {
        ipv6_payload_length_t                               icmpv6Pointer;
        ipv6_payload_length_t                               icmpv6Size;

        icmpv6Size = state->offset;
        icmpv6Pointer =
                icmpv6Size - (
                        sizeof(ipv6_extension_header_srh_t) -
                        offsetof(ipv6_extension_header_srh_t, routingType));
        state->scratchpad.icmpv6.packet =
                whip6_icmpv6CreatePacketProtoForParameterProblemMessage(
                        whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        icmpv6Size,
                        WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_ERRONEOUS_HEADER_FIELD,
                        icmpv6Pointer,
                        &state->scratchpad.icmpv6.iter
                );
    }
    else
    {
        state->scratchpad.icmpv6.packet = NULL;
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteCheckIfNumSegmentsIsCorrectOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentsLeft,
        ipv6_extension_header_srh_segments_left_t segmentsTotal
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if (segmentsLeft <= segmentsTotal)
    {
        return 0;
    }
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    if ((state->flagsAndAction & WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_DISABLE_ICMPV6_ERROR_MESSAGES) == 0)
    {
        ipv6_payload_length_t                               icmpv6Pointer;
        ipv6_payload_length_t                               icmpv6Size;

        icmpv6Size = state->offset;
        icmpv6Pointer =
                icmpv6Size - (
                        sizeof(ipv6_extension_header_srh_t) -
                        offsetof(ipv6_extension_header_srh_t, segmentsLeft));
        state->scratchpad.icmpv6.packet =
                whip6_icmpv6CreatePacketProtoForParameterProblemMessage(
                        whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        icmpv6Size,
                        WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_ERRONEOUS_HEADER_FIELD,
                        icmpv6Pointer,
                        &state->scratchpad.icmpv6.iter
                );
    }
    else
    {
        state->scratchpad.icmpv6.packet = NULL;
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DECL_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteUpdateSegmentsLeftOrDesignatePacketForDropping(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentsLeft
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX
{
    enum
    {
        MOVEBACK_OFFSET =
                sizeof(ipv6_extension_header_srh_t) -
                            offsetof(ipv6_extension_header_srh_t, segmentsLeft)
    };
    iov_blist_iter_t   iter;

    whip6_iovIteratorClone(&state->iter, &iter);
    if (whip6_iovIteratorMoveBackward(&iter, MOVEBACK_OFFSET) != MOVEBACK_OFFSET)
    {
        goto FAILURE_ROLLBACK_0;
    }
    // NOTICE iwanicki 2013-06-23:
    // A small optimization here to make everything faster.
    *iter.currElem->iov.ptr = segmentsLeft;
    return 0;

FAILURE_ROLLBACK_0:
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6ExtensionHeaderSourceRouteSetSegmentAddrAsDstAddrAndDesignatePacketForForwarding(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state,
        ipv6_extension_header_srh_segments_left_t segmentIndex,
        ipv6_extension_header_srh_segments_left_t numSegments,
        ipv6_payload_length_t headerLen
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ipv6_addr_t MCS51_STORED_IN_RAM *                   dstAddr;
    ipv6_extension_header_srh_t MCS51_STORED_IN_RAM *   srHdr;
    ipv6_payload_length_t                               segmentOffset;
    ipv6_extension_header_srh_num_octets_t              numOctetsToElide;
    ipv6_extension_header_srh_num_octets_t              numOctetsToRead;

    dstAddr =
            whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(
                    &state->processedPacket->header
            );
    if (whip6_ipv6AddrIsMulticast(dstAddr))
    {
        goto FAILURE_ROLLBACK_0;
    }
    srHdr = &state->scratchpad.sourceRouteHdr;
    numOctetsToElide = whip6_ipv6ExtensionHeaderSourceRouteGetCmprI(srHdr);
    numOctetsToRead = 16 - numOctetsToElide;
    segmentOffset = (ipv6_payload_length_t)segmentIndex * numOctetsToRead;
    if (whip6_iovIteratorMoveForward(
                &state->iter,
                segmentOffset
            ) != segmentOffset)
    {
        goto FAILURE_ROLLBACK_0;
    }
    state->offset += segmentOffset;
    headerLen -= segmentOffset;
    if (segmentIndex == numSegments - 1)
    {
        numOctetsToElide = whip6_ipv6ExtensionHeaderSourceRouteGetCmprE(srHdr);
        numOctetsToRead = 16 - numOctetsToElide;
    }
    if (whip6_iovIteratorReadAndMoveForward(
                &state->iter,
                ((uint8_t MCS51_STORED_IN_RAM *)dstAddr) + numOctetsToElide,
                numOctetsToRead
            ) != numOctetsToRead)
    {
        goto FAILURE_ROLLBACK_0;
    }
    state->offset += numOctetsToRead;
    headerLen -= numOctetsToRead;
    // NOTICE iwanicki 2013-06-22:
    // We do not check if two or more entries in the
    // addresses section are assigned to a local
    // interface and are separated by at least one
    // address not assigned to a local interface
    // (as per RFC 6554, p. 10). This may lead to
    // a routing loop, but the loop should be be
    // ultimately resolved, because at each hop
    // the segments left field is decremented.
    if (whip6_ipv6AddrIsMulticast(dstAddr))
    {
        goto FAILURE_ROLLBACK_0;
    }
    if (whip6_iovIteratorMoveForward(&state->iter, headerLen) != headerLen)
    {
        goto FAILURE_ROLLBACK_0;
    }
    state->offset += headerLen;
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_FINISH_PROCESSING_AND_FORWARD_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
    return 0;

FAILURE_ROLLBACK_0:
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
    return 1;
}
