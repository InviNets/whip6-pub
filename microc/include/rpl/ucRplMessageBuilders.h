/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_RPL_RPL_MESSAGE_BUILDERS_H__
#define __WHIP6_MICROC_RPL_RPL_MESSAGE_BUILDERS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functionality for building RPL messages.
 * For more information, refer to docs/rfc-6550.pdf.
 */

#include <base/ucIoVec.h>
#include <ipv6/ucIpv6ExtensionHeaderTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>
#include <rpl/ucRplMessageTypes.h>



/** A builder structure. */
typedef struct rpl_message_builder_s
{
    ipv6_packet_t MCS51_STORED_IN_RAM *   packet;
    iov_blist_iter_t                      iovIter;
} rpl_message_builder_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_builder_t)



/**
 * Starts building an RPL DIS message in a packet.
 * It also creates the preceding ICMPv6 header, so
 * the next header field in the previous header should
 * be (externally) set to WHIP6_IANA_IPV6_ICMP.
 * @param builder A pointer to the builder for
 *   the message.
 * @param packet The packet in which the message
 *   is being built.
 * @param iovIter An iterator over the packet's
 *   payload that should point at the first byte
 *   from which the message should start.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplStartBuildingDisMessage(
        rpl_message_builder_t * builder,
        iov_blist_iter_t const * iovIter,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Starts building an RPL DIO message in a packet.
 * It also creates the preceding ICMPv6 header, so
 * the next header field in the previous header should
 * be (externally) set to WHIP6_IANA_IPV6_ICMP.
 * @param builder A pointer to the builder for
 *   the message.
 * @param packet The packet in which the message
 *   is being built.
 * @param iovIter An iterator over the packet's
 *   payload that should point at the first byte
 *   from which the message should start.
 * @param dodagId The identifier of the DODAG.
 * @param dodagVerNo The version number of the DODAG.
 * @param rplInstanceId The instance of the RPL protocol.
 * @param rank The RPL rank.
 * @param grounded Indicates whether the DODAG is grounded.
 * @param mop The mode of operation.
 * @param prf The preference of the DODAG root.
 * @param dtsn A destination advertisement trigger sequence
 *   number for maintaining downward routes.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplStartBuildingDioMessage(
        rpl_message_builder_t * builder,
        iov_blist_iter_t const * iovIter,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        rpl_dodag_id_t MCS51_STORED_IN_RAM const * dodagId,
        rpl_dodag_version_t dodagVerNo,
        rpl_instance_id_t rplInstanceId,
        rpl_rank_t rank,
        uint8_t grounded,
        rpl_mop_t mop,
        rpl_dodag_preference_t prf,
        rpl_dest_advert_trigger_seq_no_t dtsn
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a pad-1 option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPad1(
        rpl_message_builder_t * builder
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a pad-N option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @param numBytes The number of bytes of padding.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPadN(
        rpl_message_builder_t * builder,
        uint8_t numBytes
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a DAG metric container option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @param metricDataPtr A pointer to the metric
 *   data. The data should be in the network order
 *   and they are opaque to RPL.
 * @param metricDataLen The length of the metric
 *   data.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionDagMetricContainer(
        rpl_message_builder_t * builder,
        uint8_t MCS51_STORED_IN_RAM const * metricDataPtr,
        uint8_t metricDataLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a route information option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @param prefixLen The length of the prefix in bits.
 *   Must be between 0 and 128.
 * @param prefixPtr A pointer to a prefix. Can be
 *   NULL if the prefix length is zero.
 * @param routeLiefetimeInSecs The time for which
 *   the route for the prefix remains valid.
 *   0xffffffffUL denotes infinity.
 * @param routePreference The preference of
 *   this route to the given prefix.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionRouteInformation(
        rpl_message_builder_t * builder,
        uint8_t MCS51_STORED_IN_RAM const * prefixPtr,
        uint32_t routeLiefetimeInSecs,
        uint8_t prefixLen,
        ipv6_router_preference_t routePreference
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a DODAG configuration option to an RPL
 * message in the process of building.
 * NOTICE: No authentication is assumed.
 * @param builder A pointer to the builder for
 *   the message.
 * @param pcs The path control size.
 * @param dioIntDoubl The DIO interval doubling.
 * @param dioIntMin The DIO minimal interval.
 * @param dioRedund The DIO redundancy.
 * @param maxRankIncrease The maximal rank increase
 *   for local repair.
 * @param minHopRankIncrease The minimal rank increase
 *   at each hop.
 * @param ocp The objective code point.
 * @param defLifetime The default lifetime for RPL routes.
 * @param lifetimeUnit The lifetime unit in seconds.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionDodagConfiguration(
        rpl_message_builder_t * builder,
        rpl_path_control_size_t pcs,
        rpl_interval_doublings_t dioIntDoubl,
        rpl_interval_doublings_t dioIntMin,
        rpl_interval_redundancy_t dioRedund,
        rpl_rank_t maxRankIncrease,
        rpl_rank_t minHopRankIncrease,
        rpl_ocp_t ocp,
        uint8_t defLifetime,
        uint16_t lifetimeUnit
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a solicited information option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @param dodagId The identifier of the DODAG. Can
 *   be NULL indicating that the ID is not present.
 * @param rplInstanceId The instance of the RPL protocol.
 * @param dodagVerNo The version number of the DODAG.
 * @param rplInstanceIdPresent Indicates whether the
 *   instance parameter contains a valid value.
 * @param dodagVerNoPresent Indicates whether the
 *   version parameter contains a valid value.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionSolicitedInformation(
        rpl_message_builder_t * builder,
        rpl_dodag_id_t MCS51_STORED_IN_RAM const * dodagId,
        rpl_instance_id_t rplInstanceId,
        rpl_dodag_version_t dodagVerNo,
        uint8_t rplInstanceIdPresent,
        uint8_t dodagVerNoPresent
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Adds a prefix information option to an RPL
 * message in the process of building.
 * @param builder A pointer to the builder for
 *   the message.
 * @param prefixLen The length of the prefix in bits.
 * @param onLink A flag indicating if the prefix
 *   is on-link.
 * @param autonomousAddrConf A flag indicating if
 *   autonomous address configuration is enabled.
 * @param router A flag indicating that the prefix
 *   carries a full IPv6 address.
 * @param validLifetime A valid lifetime of the
 *   prefix in seconds or 0xffffffff denoting
 *   infinity.
 * @param preferredLifetime A preferred lifetime of the
 *   prefix in seconds or 0xffffffff denoting
 *   infinity.
 * @param prefixPtr A pointer to the prefix.
 * @return Zero in case of success, or the number
 *   of bytes by which the packet should be extended
 *   to accommodate the message.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPrefixInformation(
        rpl_message_builder_t * builder,
        uint8_t prefixLen,
        uint8_t onLink,
        uint8_t autonomousAddrConf,
        uint8_t router,
        uint32_t validLifetime,
        uint32_t preferredLifetime,
        uint8_t MCS51_STORED_IN_RAM const * prefixPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_RPL_RPL_MESSAGE_BUILDERS_H__ */
