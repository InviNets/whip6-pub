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

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_MANIPULATION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains function for manipulating
 * 6LoWPAN-compatible node meshes.
 */

#include <base/ucError.h>
#include <6lowpan/uc6LoWPANMeshTypes.h>


/**
 * Resets a 6LoWPAN link table.
 * @param table The table to reset.
 *   It is assumed that the table is properly initialized.
 * @param nextBeaconSeqNo The sequence number of the next beacon.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanMeshLinkTableReset(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Searches a link table for a link with a given
 * link-layer address.
 * @param table The table to search.
 * @param addr The link-layer address.
 * @return An index of the found link or
 *   WHIP6_IEEE154_INVALID_LINK_IDX if no
 *   such link was found.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableLookupLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Searches for a link with a given address in a link
 * table. If such a link exists, its index is returned
 * Otherwise, an attempt is made to insert the link.
 * If the attempt is successful, again the index is
 * returned. Otherwise, the table remains unmodified.
 * @param table The table.
 * @param addr The link-layer address.
 * @param allowEviction Allows for eviction of another
 *   existing address if there is no space for the new one.
 * @return An index of the link with the given address or
 *   WHIP6_IEEE154_INVALID_LINK_IDX if no
 *   such link was found.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableFindExistingOrCreateNewLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr,
        uint8_t allowEviction
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Removes a given link from a link table.
 * @param table The table.
 * @param index The index of the link.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanMeshLinkTableRemoveExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the index of the first link in a link
 * table when iterating in the index order.
 * @param table The table.
 * @return index The index of the first link or
 *   WHIP6_IEEE154_INVALID_LINK_IDX if the table
 *   contains no links.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableGetFirstLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the index of the link following a given
 * link in a link table when iterating in the
 * index order.
 * @param table The table.
 * @param index The index of the given link.
 * @return index The index of the next link or
 *   WHIP6_IEEE154_INVALID_LINK_IDX if the table
 *   contains no links that have a higher index.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableGetNextLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Reports a broadcast reception for a given link in a link table.
 * @param table The table.
 * @param index The index of the link.
 * @param seqNo The sequence number of the beacon.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanMeshLinkTableReportBroadcastReceptionForExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index,
        lowpan_header_bc0_seq_no_t seqNo
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Reports a unicast completion for a given link in a link table.
 * @param table The table.
 * @param index The index of the link.
 * @param acked Nonzero if the unicast has been acknowledged or
 *   zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanMeshLinkTableReportUnicastCompletionForExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index,
        uint8_t acked
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Marks links unrefreshed in a link table for removal.
 * @param table The link table.
 * @param firstIdx The first link index to visit.
 * @param numIdx The maximal number of links to visit.
 * @return Nonzero if there are more links to visit
 *   or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_lowpanMeshLinkTableMarkUnrefreshedLinksForRemoval(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t firstIdx,
        lowpan_link_index_t numIdx
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Removes from a link table links marked for reclamation.
 * @param table The link table.
 * @param firstIdx The first link index to visit.
 * @param numIdx The maximal number of links to visit.
 * @param maxRemoved The maximal number of links to remove.
 * @return Nonzero if there are more links to visit
 *   or zero otherwise.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_lowpanMeshLinkTableRemoveLinksMarkedForRemoval(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t firstIdx,
        lowpan_link_index_t numIdx,
        lowpan_link_index_t maxRemoved
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


/**
 * Checks if a given link can be removed from a link table.
 * @param table The table.
 * @param index The index of the link.
 * @return Nonzero if the link with the given
 *   index can be removed or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_lowpanMeshLinkTableCanExistingLinkBeRemoved(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t index
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the ETX of a given link from a link table.
 * @param table The table.
 * @param index The index of the link.
 * @return The ETX value of the link.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX etx_metric_host_t whip6_lowpanMeshLinkTableGetLinkEtx(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t index
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the extended IEEE 802.15.4 address
 * associated with a given link from a link table
 * or NULL if no such an address is associated
 * with the link.
 * @param table The table.
 * @param index The index of the link.
 * @return A pointer to the address of the link or NULL.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_ext_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanMeshLinkTableGetLinkAddrExtPtr(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t index
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the short IEEE 802.15.4 address
 * associated with a given link from a link table
 * or NULL if no such an address is associated
 * with the link.
 * @param table The table.
 * @param index The index of the link.
 * @return A pointer to the address of the link or NULL.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_short_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanMeshLinkTableGetLinkAddrShortPtr(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t index
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the best IEEE 802.15.4 address associated
 * with a given link from a link table, that is, a short
 * address if it exists or an extended one otherwise.
 * @param table The table.
 * @param index The index of the link.
 * @param addr A buffer that will receive the address.
 * @return A pointer to the address of the link or NULL.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_lowpanMeshLinkTableGetLinkAddrBest(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t index,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Returns MAC pointer to the MAC state for this link.
 * @param table The table.
 * @param idx The index of the link. Must be valid.
 * @return A pointer to the MAC state.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_link_mac_state_t MCS51_STORED_IN_RAM *whip6_lowpanMeshLinkTableGetMACStateForLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#include <6lowpan/detail/uc6LoWPANMeshManipulationImpl.h>

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_MANIPULATION_H__ */
