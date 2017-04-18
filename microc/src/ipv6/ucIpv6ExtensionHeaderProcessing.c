/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#include <icmpv6/ucIcmpv6BasicMessageBuilders.h>
#include <ipv6/ucIpv6ExtensionHeaderProcessing.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6ExtensionHeaderGenericFetchAndSkipHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    size_t                  numBytes;
    ipv6_payload_length_t   hdrLen;

    state->flagsAndAction &= ~(uint8_t)WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK;
    numBytes =
            whip6_iovIteratorReadAndMoveForward(
                    &state->iter,
                    (uint8_t MCS51_STORED_IN_RAM *)&state->scratchpad.genericHdr,
                    sizeof(ipv6_extension_header_generic_t)
            );
    if (numBytes != sizeof(ipv6_extension_header_generic_t) ||
            ! whip6_iovIteratorIsValid(&state->iter))
    {
        // NOTICE iwanicki 2013-06-22:
        // In theory, we could send an ICMPv6 parameter
        // problem message with code 0 (erroneous header
        // field encountered), but let's suppress it.
        goto FAILURE_ROLLBACK_0;
    }
    hdrLen = state->scratchpad.genericHdr.hdrExtLen << 3;
    hdrLen += (sizeof(ipv6_extension_header_generic_t) + 7) & ~(ipv6_payload_length_t)0x7;
    numBytes = hdrLen - sizeof(ipv6_extension_header_generic_t);
    if (numBytes != whip6_iovIteratorMoveForward(&state->iter, numBytes))
    {
        // NOTICE iwanicki 2013-06-22:
        // In theory, we could send an ICMPv6 parameter
        // problem message with code 0 (erroneous header
        // field encountered), but let's suppress it.
        goto FAILURE_ROLLBACK_0;
    }
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_CONTINUE_PROCESSING_PACKET;
    state->nextHeader = state->scratchpad.genericHdr.nextHdr;
    state->scratchpad.icmpv6.packet = NULL;
    state->scratchpad.icmpv6.nextHdrFieldPointer =
            state->offset + offsetof(ipv6_extension_header_generic_t, nextHdr);
    state->offset += hdrLen;
    return;

FAILURE_ROLLBACK_0:
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    state->scratchpad.icmpv6.packet = NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6ExtensionHeaderGenericHandleUnrecognizedHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    state->flagsAndAction &= ~(uint8_t)WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK;
    state->flagsAndAction |= WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET;
    state->nextHeader = WHIP6_IANA_IPV6_NO_NEXT_HEADER;
    if ((state->flagsAndAction & WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_DISABLE_ICMPV6_ERROR_MESSAGES) != 0)
    {
        state->scratchpad.icmpv6.packet = NULL;
    }
    else
    {
        state->scratchpad.icmpv6.packet =
                whip6_icmpv6CreatePacketProtoForParameterProblemMessage(
                        whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                                &state->processedPacket->header
                        ),
                        state->offset,
                        WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_UNRECOGNIZED_NEXT_HEADER_TYPE,
                        state->scratchpad.icmpv6.nextHdrFieldPointer,
                        &state->scratchpad.icmpv6.iter
                );
    }
}
