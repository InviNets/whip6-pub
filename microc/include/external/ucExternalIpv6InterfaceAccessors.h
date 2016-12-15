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

#ifndef __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_INTERFACE_ACCESSORS_H__
#define __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_INTERFACE_ACCESSORS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains prototypes of functions for accessing
 * IPv6-enabled network interfaces in microc.
 */

#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>


/**
 * Returns the maximal index of an IPv6-enabled
 * network interface.
 * @return The maximal index of an IPv6-enabled
 *   network interface.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_net_iface_id_t whip6_ipv6InterfaceGetMaxId(
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns a pointer to the state of the <tt>id</tt>-th
 * IPv6-enabled network interface.
 * @param id The index of the interface.
 * @return A pointer to the interface. It is not NULL if
 *   <tt>id</tt> is at most <tt>whip6_ipv6InterfaceGetMaxId()</tt>;
 *   otherwise, it is NULL.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX ipv6_net_iface_generic_state_t MCS51_STORED_IN_RAM * whip6_ipv6InterfaceGetById(
        ipv6_net_iface_id_t id
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_EXTERNAL_EXTERNAL_IPV6_INTERFACE_ACCESSORS_H__ */
