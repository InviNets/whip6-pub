/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */

#ifndef __WHIP6_MICROC_ICMPV6_DETAIL_ICMPV6_BASIC_MESSAGE_BUILDERS_IMPL_H__
#define __WHIP6_MICROC_ICMPV6_DETAIL_ICMPV6_BASIC_MESSAGE_BUILDERS_IMPL_H__

#ifndef __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_BUILDERS_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_BUILDERS_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForDestinationUnreachableMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_DESTINATION_UNREACHABLE,
            icmpv6Code,
            0,
            iovIter
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForPacketTooBigMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        ipv6_payload_length_t icmpv6MTU,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_PACKET_TOO_BIG,
            0,
            (uint32_t)icmpv6MTU,
            iovIter
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForTimeExceededMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_TIME_EXCEEDED,
            icmpv6Code,
            0,
            iovIter
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForParameterProblemMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        icmpv6_message_parameter_problem_pointer_t icmpv6Ptr,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM,
            icmpv6Code,
            icmpv6Ptr,
            iovIter
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForEchoRequestMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_parameter_echo_identifier_t icmpv6EchoId,
        icmpv6_message_parameter_echo_seq_no_t icmpv6EchoSeqNo,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_ECHO_REQUEST,
            0,
            ((uint32_t)(icmpv6EchoId) << 16) | (uint16_t)icmpv6EchoSeqNo,
            iovIter
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForEchoReplyMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_parameter_echo_identifier_t icmpv6EchoId,
        icmpv6_message_parameter_echo_seq_no_t icmpv6EchoSeqNo,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
            srcAddr,
            dstAddr,
            packetSize,
            WHIP6_ICMPV6_MESSAGE_TYPE_ECHO_REPLY,
            0,
            ((uint32_t)(icmpv6EchoId) << 16) | (uint16_t)icmpv6EchoSeqNo,
            iovIter
    );
}

#endif /* __WHIP6_MICROC_ICMPV6_DETAIL_ICMPV6_BASIC_MESSAGE_BUILDERS_IMPL_H__ */
