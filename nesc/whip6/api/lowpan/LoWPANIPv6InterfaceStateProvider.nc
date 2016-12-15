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

#include <ieee154/ucIeee154Ipv6InterfaceStateTypes.h>


/**
 * A provider of an IPv6 network interface's state
 * for a 6LoWPAN compatible network adapter (radio).
 *
 * @author Konrad Iwanicki
 */
interface LoWPANIPv6InterfaceStateProvider
{
    /**
     * Returns a pointer to the interface state.
     * @return A pointer to the interface state.
     */
    command whip6_ipv6_net_iface_ieee154_state_t * getLoWPANInterfaceStatePtr();

}

