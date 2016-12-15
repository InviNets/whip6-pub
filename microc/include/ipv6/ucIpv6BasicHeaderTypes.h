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

#ifndef __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 header type definitions.
 * For more information, refer to the wikipedia.
 */

#include <ipv6/ucIpv6AddressTypes.h>



enum
{
    /** The version of the IP protocol: 6 :-) */
    WHIP6_IPV6_PROTOCOL_VERSION = 6,
};

enum
{
    /** The maximal value of the IPv6 hop limit field. */
    WHIP6_IPV6_PACKET_HOP_LIMIT_MAX = 255,
};

/** The version of the IP protocol. */
typedef uint8_t ipv6_protocol_version_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_protocol_version_t)

/** The traffic class class in the IPv6 protocol. */
typedef uint8_t ipv6_traffic_class_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_traffic_class_t)

/** The differentiated services code point in the IPv6 protocol. */
typedef uint8_t ipv6_dscp_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_dscp_t)

/** The explicit congestion notification in the IPv6 protocol. */
typedef uint8_t ipv6_ecn_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_ecn_t)

/** The flow label in the IPv6 protocol. */
typedef uint32_t ipv6_flow_label_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_flow_label_t)

/** The IPv6 payload length. */
typedef uint16_t ipv6_payload_length_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_payload_length_t)

/** The IPv6 next header field. */
typedef uint8_t ipv6_next_header_field_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_next_header_field_t)

/** The IPv6 routing hop limit. */
typedef uint8_t ipv6_hop_limit_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_hop_limit_t)



/** The basic IPv6 header. */
typedef struct ipv6_basic_header_s
{
    uint8_t       verTcFl[4];
    uint8_t       payloadLen[2];
    uint8_t       nextHdr;
    uint8_t       hopLimit;
    ipv6_addr_t   srcAddr;
    ipv6_addr_t   dstAddr;
} MICROC_NETWORK_STRUCT ipv6_basic_header_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_basic_header_t)


#endif /* __WHIP6_MICROC_IPV6_IPV6_BASIC_HEADER_TYPES_H__ */
