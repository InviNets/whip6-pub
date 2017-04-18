/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_TYPES_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_TYPES_H__

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the IPv6-related state of
 * a network interface running on top IEEE 802.15.4.
 */

/**
 * 802.15.4-specific flags associated with an IPv6 interface.
 */
enum
{
    WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR = (1 << 0),
};


/**
 * The state of a network interface operating
 * on top of IEEE 802.15.4.
 */
typedef struct ipv6_net_iface_ieee154_state_s
{
    ipv6_net_iface_generic_state_t   genericState;
    ieee154_ext_addr_t               ieee154ExtAddr;
    ieee154_short_addr_t             ieee154ShrtAddr;
    ieee154_pan_id_t                 ieee154PanId;
} ipv6_net_iface_ieee154_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ipv6_net_iface_ieee154_state_t)



#endif /* __WHIP6_MICROC_IEEE154_IEEE154_IPV6_INTERFACE_STATE_TYPES_H__ */
