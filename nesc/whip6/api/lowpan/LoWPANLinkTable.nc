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

#include <6lowpan/uc6LoWPANMeshTypes.h>


/**
 * A table of 6LoWPAN-compliant
 * wireless links.
 *
 * @author Konrad Iwanicki
 */
interface LoWPANLinkTable
{
    /**
     * Searches for a link with a given address.
     * @param addr The address of the link to
     *   search for.
     * @return The index of the found link or
     *   WHIP6_6LOWPAN_INVALID_LINK_IDX if no link
     *   with the given address exists in the table.
     */
    command lowpan_link_index_t findExistingLink(
            whip6_ieee154_addr_t const * addr
    );

    /**
     * Searches for a link with a given address
     * and, if such a link does not exist, attempts
     * to insert it into the link table.
     * @param addr The address of the link to
     *   insert or search for.
     * @param allowReplacing If TRUE and there is no
     *   space to allocate the new link, an existing
     *   link will be removed to make free space;
     *   otherwise, the new link will not be inserted.
     * @return The index of the found link or created link,
     *   or WHIP6_6LOWPAN_INVALID_LINK_IDX if no link
     *   with the given address exists in the table.
     */
    command lowpan_link_index_t findExistingLinkOrCreateNewOne(
            whip6_ieee154_addr_t const * addr,
            bool allowReplacing
    );

    /**
     * Removes a link with a given index from
     * the table, either immediately or as
     * soon as it is possible.
     * @param index The index of the link.
     * @param force If TRUE the link will be removed
     *   immediately; otherwise, it will be marked
     *   for removal and removed as soon as possible,
     *   but from a different task.
     */
    command void removeExistingLink(
            lowpan_link_index_t idx
    );

    /**
     * Returns the first link in the link table
     * in the order of increasing indexes.
     * @return An index of the first link in the
     *   table or WHIP6_6LOWPAN_INVALID_LINK_IDX
     *   if the table contains no links.
     */
    command lowpan_link_index_t getFirstLink();

    /**
     * Returns the next link in the link table
     * following a given link in the order of
     * increasing indexes.
     * @param prevIdx The given link.
     * @return An index of the next link in the
     *   table or WHIP6_6LOWPAN_INVALID_LINK_IDX
     *   if the table contains no links with
     *   higher indexes.
     */
    command lowpan_link_index_t getNextLink(
            lowpan_link_index_t prevIdx
    );

    /**
     * Returns a pointer to an extended IEEE 802.15.4
     * address associated with a link.
     * Can be NULL if no such an address is associated.
     * @param idx The index of the link.
     * @return A pointer to the extended link address
     *   or NULL.
     */
    command whip6_ieee154_ext_addr_t const * getExtAddrPtrForLink(
            lowpan_link_index_t idx
    );

    /**
     * Returns a pointer to a short IEEE 802.15.4
     * address associated with a link.
     * Can be NULL if no such an address is associated.
     * @param idx The index of the link.
     * @return A pointer to the extended link address
     *   or NULL.
     */
    command whip6_ieee154_short_addr_t const * getShortAddrPtrForLink(
            lowpan_link_index_t idx
    );

    /**
     * Returns the best (shortest) IEEE 802.15.4
     * address associated with a link.
     * @param idx The index of the link.
     * @param addr A buffer for the address.
     */
    command void getBestAddrForLink(
            lowpan_link_index_t idx,
            whip6_ieee154_addr_t * addr
    );

    /**
     * Returns the ETX for a link with a given index.
     * @param idx The index of the link.
     * @return The ETX for the link.
     */
    command etx_metric_host_t getEtxForLink(
            lowpan_link_index_t idx
    );

    /**
     * Reports a reception of a broadcast frame for
     * a link with a given index.
     * @param idx The index of the link.
     * @param seqNo The sequence number of the frame.
     */
    command void reportBroadcastReceptionForLink(
            lowpan_link_index_t idx,
            lowpan_header_bc0_seq_no_t seqNo
    );

    /**
     * Reports an acknowledged transmission of a unicast
     * frame for a link with a given index.
     * @param idx The index of the link.
     */
    command void reportAcknowledgedUnicastForLink(
            lowpan_link_index_t idx
    );

    /**
     * Reports an unacknowledged transmission of a unicast
     * frame for a link with a given index.
     * @param idx The index of the link.
     */
    command void reportUnacknowledgedUnicastForLink(
            lowpan_link_index_t idx
    );

    /**
     * Returns MAC pointer to the MAC state for this link.
     * @param idx The index of the link.
     * @return A pointer to the MAC state.
     */
    command whip6_lowpan_link_mac_state_t *getMacState(
            lowpan_link_index_t idx);
}

