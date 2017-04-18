/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_TYPES_H__
#define __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_TYPES_H__

#include <ipv6/ucIpv6AddressTypes.h>

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the IPv6-related state of
 * a network interface, notably the prefixes
 * associated with the interface. The state is
 * generic in that it does not depend on the
 * particular link-layer technology employed.
 */

enum
{
    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_MASK = 0x0f,
    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_INDEX_SHIFT = 0,

    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_MASK = 0xf0,
    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_SHIFT = 4,

    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_LOOPBACK = 0,
    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_IEEE154 = 1,
};

/**
 * Generic flags associated with an IPv6 interface.
 * Link-layer technology specific flags should
 * be allocated from the bottom space.
 */
enum
{
    WHIP6_IPV6_NET_IFACE_GENERIC_STATE_FLAG_IS_ON = (1 << 7),
};


/** The index of a network interface. */
typedef uint8_t   ipv6_net_iface_id_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_net_iface_id_t)

/** The number of addresses assigned to a network interface. */
typedef uint8_t   ipv6_net_iface_addr_count_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_net_iface_addr_count_t)



struct ipv6_net_iface_generic_state_s;
typedef struct ipv6_net_iface_generic_state_s ipv6_net_iface_generic_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_net_iface_generic_state_t)

/**
 * The state of a generic network interface.
 */
struct ipv6_net_iface_generic_state_s
{
    ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM *   next;
    ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM *   prev;
    ipv6_net_iface_id_t                                    indexAndType;
    uint8_t                                                flags;
    ipv6_net_iface_addr_count_t                            unicastAddrArrLen;
    ipv6_net_iface_addr_count_t                            multicastAddrArrLen;
    ipv6_addr_t MCS51_STORED_IN_RAM *                      unicastAddrArrPtr;
    ipv6_addr_t MCS51_STORED_IN_RAM *                      multicastAddrArrPtr;
};

typedef ipv6_net_iface_generic_state_t ipv6_net_iface_loopback_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_net_iface_loopback_state_t)


#endif /* __WHIP6_MICROC_IPV6_IPV6_GENERIC_INTERFACE_STATE_TYPES_H__ */
