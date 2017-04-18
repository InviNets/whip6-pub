/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"


/**
 * A provider for a local IEEE 802.15.4 address.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154LocalAddressProvider
{
    /**
     * Returns the extended IEEE 802.15.4 address
     * assigned to the present node. It is
     * assumed that a node always has such an address.
     * @param addr A buffer that will receive the
     *   address.
     */
    command void getExtAddr(whip6_ieee154_ext_addr_t * addr);

    /**
     * Returns a pointer to the extended IEEE 802.15.4
     * address assigned to the present node. It is
     * assumed that a node always has such an address.
     * @return A pointer to the extended address.
     */
    command whip6_ieee154_ext_addr_t const * getExtAddrPtr();

    /**
     * Checks if the present node has a short
     * address.
     * @return TRUE if the node has such an address,
     *   or FALSE otherwise.
     */
    command bool hasShortAddr();

    /**
     * Returns the short IEEE 802.15.4 address
     * assigned to the present node. If the
     * node does not have such an address, the
     * result is undefined.
     * @param addr A buffer that will receive the
     *   address.
     */
    command void getShortAddr(whip6_ieee154_short_addr_t * addr);

    /**
     * Returns a pointer to the short IEEE 802.15.4
     * address assigned to the present node. If the
     * node does not have such an address, the result
     * is undefined.
     * @return A pointer to the short address.
     */
    command whip6_ieee154_short_addr_t const * getShortAddrPtr();

    /**
     * Returns the best IEEE 802.15.4 address
     * assigned to the present node. If the node
     * has a short address, it is returned. Otherwise,
     * an extended address is returned.
     * @param addr A buffer that will receive the
     *   address.
     */
    command void getAddr(whip6_ieee154_addr_t * addr);

    /**
     * Returns a pointer to the best IEEE 802.15.4 address
     * assigned to the present node. If the node
     * has a short address, it is returned. Otherwise,
     * an extended address is returned.
     * @return A pointer to the address.
     */
    command whip6_ieee154_addr_t const * getAddrPtr();

    /**
     * Returns the identifier of the PAN
     * in which the present node participates.
     * @param panId A buffer that will receive the
     *   PAN identifier.
     */
    command void getPanId(whip6_ieee154_pan_id_t * panId);

    /**
     * Returns a pointer to the identifier of the PAN
     * in which the present node participates.
     * @return A pointer to the PAN identifier.
     */
    command whip6_ieee154_pan_id_t const * getPanIdPtr();
}
