/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>


/**
 * A provider of an IPv6 network interface's state.
 *
 * @author Konrad Iwanicki
 */
interface IPv6InterfaceStateProvider
{
    /**
     * Returns a pointer to the interface state.
     * @return A pointer to the interface state or
     *   NULL if no interface is connected.
     */
    command whip6_ipv6_net_iface_generic_state_t * getInterfaceStatePtr();

}
