/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_PACKET_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_PACKET_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 packet type definitions.
 * For more information, refer to the wikipedia.
 */

#include <base/ucIoVec.h>
#include <ipv6/ucIpv6BasicHeaderTypes.h>



/**
 * An IPv6 packet.
 */
typedef struct ipv6_packet_s
{
    ipv6_basic_header_t                 header;
    iov_blist_t MCS51_STORED_IN_RAM *   firstPayloadIov;
    iov_blist_t MCS51_STORED_IN_RAM *   lastPayloadIov;
} ipv6_packet_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_packet_t)

#endif /* __WHIP6_MICROC_IPV6_IPV6_PACKET_TYPES_H__ */
