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

#ifndef __WHIP6_MICROC_IPV6_IPV6_HEADER_PROCESSOR_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_HEADER_PROCESSOR_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains type definitions used for
 * processing headers of IPv6 packets.
 */

#include <base/ucIoVec.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <ipv6/ucIpv6BasicHeaderTypes.h>
#include <ipv6/ucIpv6ExtensionHeaderTypes.h>
#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>
#include <srcroute/ucSourceRouteExtensionHeaderTypes.h>




enum
{
    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE = (1 << 7),
    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING = (1 << 6),
    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS = (1 << 5),
    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS = (1 << 1),
    WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED = (1 << 0),
};


/**
 * A scratchpad for a processing state associated with
 * an outgoing packet that is specific to loopback interfaces.
 */
typedef struct ipv6_out_packet_processing_state_scratchpad_loopback_specific_s
{
    uint8_t   trash;
} ipv6_out_packet_processing_state_scratchpad_loopback_specific_t;

/**
 * A scratchpad for a processing state associated with
 * an outgoing packet that is specific to 6LoWPAN interfaces.
 */
typedef struct ipv6_out_packet_processing_state_scratchpad_lowpan_specific_s
{
    ieee154_addr_t   nextHopLinkLayerAddr;
} ipv6_out_packet_processing_state_scratchpad_lowpan_specific_t;


/**
 * A scratchpad for a processing state associated with
 * an outgoing packet that is specific to a given link-layer
 * interface type.
 */
typedef union ipv6_out_packet_processing_state_scratchpad_iface_specific_u
{
    ipv6_out_packet_processing_state_scratchpad_loopback_specific_t   loopback;
    ipv6_out_packet_processing_state_scratchpad_lowpan_specific_t     lowpan;
} ipv6_out_packet_processing_state_scratchpad_iface_specific_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_out_packet_processing_state_scratchpad_iface_specific_t)



/**
 * A processing state associated with an outgoing packet.
 */
typedef struct ipv6_out_packet_processing_state_s
{
    /** The packet. */
    ipv6_packet_t MCS51_STORED_IN_RAM *                            packet;
    /** Processing flags (see above). */
    uint8_t                                                        flags;
    /** The id of the interface to which the packet has been assigned. */
    ipv6_net_iface_id_t                                            ifaceId;
    /** An interface-specific scratchpad. */
    ipv6_out_packet_processing_state_scratchpad_iface_specific_t   ifaceScratchpad;
} ipv6_out_packet_processing_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_out_packet_processing_state_t)



enum
{
    WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_PROCESSING_DONE = (1 << 7),
    WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_BEING_PROCESSED = (1 << 6),
    WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_DESTINED_AT_IFACE = (1 << 5),
};



/**
 * A processing state associated with an incoming packet.
 */
typedef struct ipv6_in_packet_processing_state_s
{
    /** The packet. */
    ipv6_packet_t MCS51_STORED_IN_RAM *                            packet;
    /** An iterator over the packet's payload. */
    iov_blist_iter_t                                               payloadIter;
    /** The offset within the packet (including the IPv6 header). */
    ipv6_payload_length_t                                          payloadOffset;
    /** Processing flags (see above). */
    uint8_t                                                        flags;
    /** The id of the interface at which the packet has been received. */
    ipv6_net_iface_id_t                                            ifaceId;
    /** The next IPv6 header value. */
    ipv6_next_header_field_t                                       nextHeaderId;
} ipv6_in_packet_processing_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_in_packet_processing_state_t)



// ********************** FIXME: Remove the trash below


enum
{
    WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_PRESENT_NODE_IS_DESTINATION = (1 << 7),
    WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_DISABLE_ICMPV6_ERROR_MESSAGES = (1 << 6),

    WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_CONTINUE_PROCESSING_PACKET = 0,
    WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_FINISH_PROCESSING_AND_FORWARD_PACKET = 1,
    WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_TAKE_OVER_PACKET = 2,
    WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_DROP_PACKET = 3,
};

enum
{
    WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK = (uint8_t)0x03,
    WHIP6_IPV6_PACKET_PROCESSING_STATE_FLAG_MASK = (uint8_t)~WHIP6_IPV6_PACKET_PROCESSING_STATE_ACTION_MASK,
};

/**
 * A scratchpad for an IPv6 packet processor
 * that allows for preparing ICMPv6 messages.
 */
typedef struct ipv6_in_packet_processing_scratchpad_icmpv6_packet_builder_s
{
    iov_blist_iter_t                             iter;
    ipv6_packet_t MCS51_STORED_IN_RAM *          packet;
    icmpv6_message_parameter_problem_pointer_t   nextHdrFieldPointer;
} ipv6_in_packet_processing_scratchpad_icmpv6_packet_builder_t;

/**
 * A scratchpad for an IPv6 packet processor.
 */
typedef union ipv6_in_packet_processing_scratchpad_u
{
    ipv6_extension_header_generic_t                                genericHdr;
    ipv6_extension_header_srh_t                                    sourceRouteHdr;
    ipv6_in_packet_processing_scratchpad_icmpv6_packet_builder_t   icmpv6;
} ipv6_in_packet_processing_scratchpad_t;

/**
 * A state of an IPv6 packet processor.
 */
typedef struct ipv6_in_packet_processing_state_xxx_s
{
    /** An iterator over the packet's payload. */
    iov_blist_iter_t                                       iter;
    /** The packet. */
    ipv6_packet_t MCS51_STORED_IN_RAM *                    processedPacket;
    /** The offset within the packet (including the IPv6 header). */
    ipv6_payload_length_t                                  offset;
    /** The id of the interface over which the packet was received. */
    ipv6_net_iface_id_t                                    ifaceId;
    /** Processing flags and action (see above). */
    uint8_t                                                flagsAndAction;
    /** The next IPv6 header value. */
    ipv6_next_header_field_t                               nextHeader;
    /** A scratchpad for temporary data. */
    ipv6_in_packet_processing_scratchpad_t                 scratchpad;
} ipv6_in_packet_processing_state_xxx_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_in_packet_processing_state_xxx_t)

#endif /* __WHIP6_MICROC_IPV6_IPV6_HEADER_PROCESSOR_TYPES_H__ */
