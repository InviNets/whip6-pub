/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_UDP_UDP_BASIC_TYPES_H__
#define __WHIP6_MICROC_UDP_UDP_BASIC_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic types for the
 * User Datagram Protocol (UDP).
 */

#include <base/ucTypes.h>
#include <ipv6/ucIpv6AddressTypes.h>


/** A UDP port number. */
typedef uint16_t   udp_port_no_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(udp_port_no_t)

/** A UDP socket address: a combination of an IP address and port number. */
typedef struct udp_socket_addr_s
{
    ipv6_addr_t     ipv6Addr;
    udp_port_no_t   udpPortNo;
} udp_socket_addr_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(udp_socket_addr_t)

/** A UDP socket identifier. */
typedef uint8_t   udp_socket_id_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(udp_socket_id_t)

#endif /* __WHIP6_MICROC_UDP_UDP_BASIC_TYPES_H__ */
