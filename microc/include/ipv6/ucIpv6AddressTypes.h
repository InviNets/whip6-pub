/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_ADDRESS_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_ADDRESS_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 address type definitions.
 * For more information, refer to the wikipedia.
 */

#include <base/ucTypes.h>


enum
{
    IPV6_ADDRESS_LENGTH_IN_BYTES = 16,
};

enum
{
    IPV6_ADDRESS_SCOPE_INTERFACE_LOCAL = 0x1,
    IPV6_ADDRESS_SCOPE_LINK_LOCAL = 0x2,
    IPV6_ADDRESS_SCOPE_ADMIN_LOCAL = 0x4,
    IPV6_ADDRESS_SCOPE_SITE_LOCAL = 0x5,
    IPV6_ADDRESS_SCOPE_ORGANIZATION_LOCAL = 0x8,
    IPV6_ADDRESS_SCOPE_GLOBAL = 0xe,
    IPV6_ADDRESS_SCOPE_MAX_RESERVED = 0xf,
};

/**
 * An IPv6 address.
 */
typedef struct ipv6_addr_s
{
    uint8_t   data8[IPV6_ADDRESS_LENGTH_IN_BYTES];
} MICROC_NETWORK_STRUCT ipv6_addr_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_addr_t)


/** The scope of an IPv6 address. */
typedef uint8_t   ipv6_addr_scope_t;


#endif /* __WHIP6_MICROC_IPV6_IPV6_ADDRESS_TYPES_H__ */
