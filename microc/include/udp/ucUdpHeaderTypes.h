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

#ifndef __WHIP6_MICROC_UDP_UDP_HEADER_TYPES_H__
#define __WHIP6_MICROC_UDP_UDP_HEADER_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the types related to the
 * header of the User Datagram Protocol (UDP).
 * For more information, refer to the wikipedia.
 */

#include <base/ucTypes.h>
#include <udp/ucUdpBasicTypes.h>

/**
 * A UDP header.
 */
typedef struct udp_header_s
{
    uint8_t   srcPort[2];
    uint8_t   dstPort[2];
    uint8_t   length[2];
    uint8_t   checksum[2];
} MICROC_NETWORK_STRUCT udp_header_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(udp_header_t)


#endif /* __WHIP6_MICROC_UDP_UDP_HEADER_TYPES_H__ */
