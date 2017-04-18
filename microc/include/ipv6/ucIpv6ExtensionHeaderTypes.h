/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 extension header type definitions.
 * For more information, refer to the wikipedia.
 */

#include <ipv6/ucIpv6AddressTypes.h>

/** A generic IPv6 extension header. */
typedef struct ipv6_extension_header_generic_s
{
    uint8_t       nextHdr;
    uint8_t       hdrExtLen;
} MICROC_NETWORK_STRUCT ipv6_extension_header_generic_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_extension_header_generic_t)


enum
{
    IPV6_ROUTER_PREFERENCE_HIGH = 0x01,
    IPV6_ROUTER_PREFERENCE_MEDIUM = 0x00,
    IPV6_ROUTER_PREFERENCE_LOW = 0x11,
};

enum
{
    IPV6_ROUTER_PREFERENCE_MASK = 0x11,
};

typedef uint8_t   ipv6_router_preference_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_router_preference_t)

#endif /* __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_TYPES_H__ */
