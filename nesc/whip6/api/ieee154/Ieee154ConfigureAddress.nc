/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "Ieee154.h"

interface Ieee154ConfigureAddress {
    /**
     * Sets the Ieee154 link layer addresses. Address pointers may
     * or may not be stored, so you shouldn't modify the address objects.
     * @param panId - Can be NULL. In that case default will be used.
     * @param extAddr - Must not be NULL.
     * @param shrtAddr - Can be NULL. In that case, the node will only have
     *                   the extended address.
     */
    command void setAddress(whip6_ieee154_pan_id_t const *panIdPtr,
                            whip6_ieee154_ext_addr_t const *extAddrPtr,
                            whip6_ieee154_short_addr_t const *shrtAddrPtr);
}
