/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_BUILDERS_H__
#define __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_BUILDERS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functions for building
 * basic ICMPv6 messages.
 * For more information, see docs/rfc4443.pdf
 */

#include <base/ucIoVec.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * Creates an IPv6 packet containing
 * a common-format ICMPv6 message.
 * More specifically, fills in the IPv6
 * header and the first 8 octets of
 * the message, and sets the iterator
 * to point after these octets, so that
 * additional data can be appended to
 * the message.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param icmpv6Type The type field of the message.
 * @param icmpv6Code The code field of the message.
 * @param icmpv6RemainingFourOctets The four octets
 *   after the basic ICMPv6 header.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which
 *   additional data can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one. In the
 *   latter case, the iterator will remain
 *   unchanged.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_type_t icmpv6Type,
        icmpv6_message_code_t icmpv6Code,
        uint32_t icmpv6RemainingFourOctets,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 destination unreachable message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy the contents
 * of the original packet into the message.
 * Neither does it compute the checksum
 * of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param icmpv6Code The code field of the message.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForDestinationUnreachableMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 packet too big message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy the contents
 * of the original packet into the message.
 * Neither does it compute the checksum
 * of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param icmpv6MTU An MTU value.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForPacketTooBigMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        ipv6_payload_length_t icmpv6MTU,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 time exceeded message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy the contents
 * of the original packet into the message.
 * Neither does it compute the checksum
 * of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param icmpv6Code The code field of the message.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForTimeExceededMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 parameter problem message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy the contents
 * of the original packet into the message.
 * Neither does it compute the checksum
 * of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param icmpv6Ptr A pointer to the packet.
 * @param icmpv6Code The code field of the message.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForParameterProblemMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_code_t icmpv6Code,
        icmpv6_message_parameter_problem_pointer_t icmpv6Ptr,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 echo request message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy put any data
 * into the message. Neither does it compute
 * the checksum of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param icmpv6EchoId An identifier of the message.
 * @param icmpv6EchoSeqNo A sequence number of the message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForEchoRequestMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_parameter_echo_identifier_t icmpv6EchoId,
        icmpv6_message_parameter_echo_seq_no_t icmpv6EchoSeqNo,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Creates an IPv6 packet containing an
 * ICMPv6 echo request message.
 * This function only reserves memory
 * for the packet and fills in the packet's
 * header. It does not copy put any data
 * into the message. Neither does it compute
 * the checksum of the packet.
 * @param srcAddr The source address of
 *   the present node.
 * @param dstAddr The address of the
 *   final destination node.
 * @param packetSize The length of the ICMPv6
 *   message.
 * @param icmpv6EchoId An identifier of the message.
 * @param icmpv6EchoSeqNo A sequence number of the message.
 * @param iovIter An iterator that will point
 *   to the place in the packet to which the
 *   original packet can be copied.
 * @return A pointer to the packet or NULL
 *   if there is no memory to allocate one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForEchoReplyMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_parameter_echo_identifier_t icmpv6EchoId,
        icmpv6_message_parameter_echo_seq_no_t icmpv6EchoSeqNo,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



#include <icmpv6/detail/ucIcmpv6BasicMessageBuildersImpl.h>

#endif /* __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_MESSAGE_BUILDERS_H__ */
