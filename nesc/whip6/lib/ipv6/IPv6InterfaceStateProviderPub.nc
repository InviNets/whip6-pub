/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <external/ucExternalIpv6InterfaceAccessors.h>
#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>


/**
 * An implementation of a provider of IPv6
 * network interfacess state.
 *
 * @author Konrad Iwanicki
 */
module IPv6InterfaceStateProviderPub
{
    provides interface IPv6InterfaceStateProvider as Interfaces[ipv6_net_iface_id_t idx];
    uses interface IPv6InterfaceStateProvider as SubInterfaces[ipv6_net_iface_id_t idx];
}
implementation
{
    enum
    {
        NUM_INTERFACES = uniqueCount("IPv6Stack::Iface"),
    };

    command inline whip6_ipv6_net_iface_generic_state_t * Interfaces.getInterfaceStatePtr[ipv6_net_iface_id_t idx]()
    {
        return call SubInterfaces.getInterfaceStatePtr[idx]();
    }

    default command inline whip6_ipv6_net_iface_generic_state_t * SubInterfaces.getInterfaceStatePtr[ipv6_net_iface_id_t idx]()
    {
        return NULL;
    }

    ipv6_net_iface_id_t whip6_ipv6InterfaceGetMaxId(
    ) @C() @spontaneous() // __attribute__((banked))
    {
        return NUM_INTERFACES - 1;
    }

    whip6_ipv6_net_iface_generic_state_t * whip6_ipv6InterfaceGetById(
            ipv6_net_iface_id_t idx
    ) @C() @spontaneous() // __attribute__((banked))
    {
        return call Interfaces.getInterfaceStatePtr[idx]();
    }
    
}
