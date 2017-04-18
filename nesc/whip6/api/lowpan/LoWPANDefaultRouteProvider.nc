/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ieee154/ucIeee154AddressTypes.h>


/**
 * A provider of an IEEE 802.15.4 address
 * representing a default route.
 *
 * @author Konrad Iwanicki
 */
interface LoWPANDefaultRouteProvider
{

    /**
     * Provides an IEEE 802.15.4 address that
     * represents a default route.
     * @param addr A buffer that will receive
     *   the address representing the default
     *   route. If there is no such route, the
     *   address will be set to
     *   <tt>IEEE154_ADDR_MODE_NONE</tt>.
     */
    command void getDefaultRouteLinkLayerAddr(
            whip6_ieee154_addr_t * addr
    );

}
