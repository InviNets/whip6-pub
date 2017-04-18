/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANMeshManipulation.h>


/**
 * An implementation of a table of
 * 6LoWPAN-compliant wireless links.
 *
 * @param max_num_links The maximal number of
 *   links in the table.
 * @param ext_addr_hash_table_len The length of
 *   the hash table indexed by extended IEEE
 *   802.15.4 addresses. Must be at least 1.
 * @param short_addr_hash_table_len The length
 *   of the hash table indexed by short IEEE
 *   802.15.4 addresses. Must be at least 1.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANLinkTablePrv(
    lowpan_link_index_t max_num_links,
    lowpan_link_index_t ext_addr_hash_table_len,
    lowpan_link_index_t short_addr_hash_table_len
)
{
    provides
    {
        interface Init;
        interface LoWPANLinkTable as LinkTable;
    }
}
implementation
{

    enum
    {
        MAX_NUM_LINKS = max_num_links,
        EXT_ADDR_HASH_TABLE_LEN = ext_addr_hash_table_len,
        SHORT_ADDR_HASH_TABLE_LEN = short_addr_hash_table_len,
    };


    whip6_lowpan_link_t         m_linkPool[MAX_NUM_LINKS];
    whip6_lowpan_link_index_t   m_extAddrHashTable[EXT_ADDR_HASH_TABLE_LEN];
    whip6_lowpan_link_index_t   m_shortAddrHashTable[SHORT_ADDR_HASH_TABLE_LEN];
    whip6_lowpan_link_table_t   m_linkTable = {
        linkPoolPtr: &(m_linkPool[0]),
        extAddrHashMapPtr: &(m_extAddrHashTable[0]),
        shrtAddrHashMapPtr: &(m_shortAddrHashTable[0]),
        linkPoolLen: MAX_NUM_LINKS,
        extAddrHashMapLen: EXT_ADDR_HASH_TABLE_LEN,
        shrtAddrHashMapLen: SHORT_ADDR_HASH_TABLE_LEN,
        firstLinkInPool: 0,
    };


    command inline error_t Init.init()
    {
        whip6_lowpanMeshLinkTableReset(&m_linkTable);
        return SUCCESS;
    }



    command inline lowpan_link_index_t LinkTable.findExistingLink(
            whip6_ieee154_addr_t const * addr
    )
    {
        return whip6_lowpanMeshLinkTableLookupLink(
                &m_linkTable,
                addr
        );
    }



    command inline lowpan_link_index_t LinkTable.findExistingLinkOrCreateNewOne(
            whip6_ieee154_addr_t const * addr,
            bool allowReplacing
    )
    {
        return whip6_lowpanMeshLinkTableFindExistingOrCreateNewLink(
                &m_linkTable,
                addr,
                allowReplacing
        );
    }



    command inline void LinkTable.removeExistingLink(
            lowpan_link_index_t idx
    )
    {
        whip6_lowpanMeshLinkTableRemoveExistingLink(
                &m_linkTable,
                idx
        );
    }



    command inline lowpan_link_index_t LinkTable.getFirstLink()
    {
        return whip6_lowpanMeshLinkTableGetFirstLink(
                &m_linkTable
        );
    }



    command inline lowpan_link_index_t LinkTable.getNextLink(
            lowpan_link_index_t prevIdx
    )
    {
        return whip6_lowpanMeshLinkTableGetNextLink(
                &m_linkTable,
                prevIdx
        );
    }



    command whip6_ieee154_ext_addr_t const * LinkTable.getExtAddrPtrForLink(
            lowpan_link_index_t idx
    )
    {
        return whip6_lowpanMeshLinkTableGetLinkAddrExtPtr(
                &m_linkTable,
                idx
        );
    }



    command whip6_ieee154_short_addr_t const * LinkTable.getShortAddrPtrForLink(
            lowpan_link_index_t idx
    )
    {
        return whip6_lowpanMeshLinkTableGetLinkAddrShortPtr(
                &m_linkTable,
                idx
        );
    }



    command inline void LinkTable.getBestAddrForLink(
            lowpan_link_index_t idx,
            whip6_ieee154_addr_t * addr
    )
    {
        whip6_lowpanMeshLinkTableGetLinkAddrBest(
                &m_linkTable,
                idx,
                addr
        );
    }



    command inline etx_metric_host_t LinkTable.getEtxForLink(
            lowpan_link_index_t idx
    )
    {
        return whip6_lowpanMeshLinkTableGetLinkEtx(
                &m_linkTable,
                idx
        );
    }



    command inline void LinkTable.reportBroadcastReceptionForLink(
            lowpan_link_index_t idx,
            lowpan_header_bc0_seq_no_t seqNo
    )
    {
        whip6_lowpanMeshLinkTableReportBroadcastReceptionForExistingLink(
                &m_linkTable,
                idx,
                seqNo
        );
    }



    command inline void LinkTable.reportAcknowledgedUnicastForLink(
            lowpan_link_index_t idx
    )
    {
        whip6_lowpanMeshLinkTableReportUnicastCompletionForExistingLink(
                &m_linkTable,
                idx,
                TRUE
        );
    }



    command inline void LinkTable.reportUnacknowledgedUnicastForLink(
            lowpan_link_index_t idx
    )
    {
        whip6_lowpanMeshLinkTableReportUnicastCompletionForExistingLink(
                &m_linkTable,
                idx,
                FALSE
        );
    }

    command whip6_lowpan_link_mac_state_t *LinkTable.getMacState(
            lowpan_link_index_t idx) {
        return whip6_lowpanMeshLinkTableGetMACStateForLink(
                &m_linkTable,
                idx
        );
    }
}
