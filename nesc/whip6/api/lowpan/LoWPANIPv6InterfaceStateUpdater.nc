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
 * A updater of an IPv6 network interface's state
 * for a 6LoWPAN compatible network adapter (radio).
 *
 * @author Konrad Iwanicki
 */
interface LoWPANIPv6InterfaceStateUpdater
{

    /**
     * Updates the addresses maintained by an interface
     * after a short IEEE 802.15.4 address has been updated.
     */
    command void updateIPv6AddressesAfterShortIeee154AddressUpdate();
    
}

