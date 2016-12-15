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

#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>


/**
 * An updater of an IPv6 network interface's state.
 *
 * @author Konrad Iwanicki
 */
interface IPv6InterfaceStateUpdater
{

    /**
     * Clears all addresses associated with a network
     * interface.
     */
    command void clearAssociatedAddresses();

    /**
     * Associates a new undefined unicast IPv6 address
     * with a network interface and puts it at the end
     * of the address list.
     * @return A pointer to the address or NULL if no more
     *   addresses can be associated.
     */
    command whip6_ipv6_addr_t * addNewUnicastAddressAsLast();

    /**
     * Compacts the address lists, that is, clears all
     * the undefined addresses.
     */
    command void compactAssociatedAddresses();

}

