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

#ifndef __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_TYPES_H__
#define __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the definition of an IPv6
 * extension header that allows for source
 * routing in combination with RPL.
 * For more information, refer to docs/rfc6554.pdf.
 */

#include <ipv6/ucIpv6ExtensionHeaderTypes.h>



typedef uint8_t ipv6_extension_header_srh_routing_type_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_extension_header_srh_routing_type_t)

typedef uint8_t ipv6_extension_header_srh_segments_left_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_extension_header_srh_segments_left_t)

typedef uint8_t ipv6_extension_header_srh_num_octets_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_extension_header_srh_num_octets_t)


enum
{
    WHIP6_IPV6_EXTENSION_HEADER_SOURCE_ROUTE_SUPPORTED_ROUTING_TYPE = 3,
};


/** The IPv6 extension header for source routing. */
typedef struct ipv6_extension_header_srh_s
{
    uint8_t       nextHdr;
    uint8_t       hdrExtLen;
    uint8_t       routingType;
    uint8_t       segmentsLeft;
    uint8_t       cmprX;
    uint8_t       padAndReserved[3];
} ipv6_extension_header_srh_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_extension_header_srh_t)


#endif /* __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_TYPES_H__ */
