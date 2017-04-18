/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_TYPES_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains types for meshing
 * 6LoWPAN-compatible nodes.
 */

#include <base/ucEtx.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <6lowpan/uc6LoWPANHeaderTypes.h>


/**
 * A counter for 6LoWPAN links.
 */
typedef uint8_t   lowpan_link_index_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_index_t)

/**
 * Flags for 6LoWPAN links.
 */
typedef uint8_t   lowpan_link_flags_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_flags_t)

/**
 * MAC layer information related to that link.
 */
typedef struct lowpan_link_mac_state_s
{
    // Timestamp taken at the end-of-frame-rx moment for the latest
    // received beacon.
    uint32_t lastBeaconTimestamp;
    // Random state recorded in the last received beacon.
    uint32_t lastBeaconRandState;
    // Drift compensation coefficient. If the clock of this link is slower
    // by 310.24 ppm, then driftCompenation == -31024
    int16_t driftCompensation;
    // Similar to the fields above, end-of-frame-rx timestamp and state for
    // the beacon used to estimate drift compensation.
    uint32_t driftBeaconTimestamp;
    uint32_t driftBeaconRandState;

} lowpan_link_mac_state_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_mac_state_t)

/**
 * If randomGenState == WHIP6_6LOWPAN_EMPTY_RANDOM_GEN_STATE
 * then we assume that there is no MAC information available
 */
enum
{
    WHIP6_6LOWPAN_MAC_EMPTY_TIMESTAMP = 42,
    WHIP6_6LOWPAN_MAC_NO_COMPENSATION_DATA = 0x7FFF,
};

/**
 * A quality of a 6LoWPAN link.
 */
typedef struct lowpan_link_quality_data_s
{
    etx_metric_host_t            etx;
    lowpan_header_bc0_seq_no_t   lastBeaconSeqNo;
    uint8_t                      numReceivedBeacons;
    uint8_t                      numMissedBeacons;
    uint8_t                      numAckedUnicasts;
    uint8_t                      numUnackedUnicasts;
    prr_metric_host_t            inPrr;
} lowpan_link_quality_data_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_quality_data_t)



enum
{
    WHIP6_6LOWPAN_INVALID_LINK_IDX = 0xff,
};

enum
{
    WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR = (1 << 7),
    WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR = (1 << 6),
    WHIP6_6LOWPAN_LINK_FLAG_INIT = (1 << 5),
    WHIP6_6LOWPAN_LINK_FLAG_REFRESHED = (1 << 4),
    WHIP6_6LOWPAN_LINK_FLAG_RECLAIMABLE = (1 << 3),
    WHIP6_6LOWPAN_LINK_FLAG_PINNED = (1 << 1),
};


/**
 * A 6LoWPAN link.
 */
typedef struct lowpan_link_s
{
    ieee154_ext_addr_t           extAddr;
    ieee154_short_addr_t         shrtAddr;
    lowpan_link_index_t          idx;
    lowpan_link_flags_t          flags;
    lowpan_link_quality_data_t   quality;
    lowpan_link_mac_state_t      mac;
    lowpan_link_index_t          nextExtAddrIdx;
    lowpan_link_index_t          nextShrtAddrIdx;
} lowpan_link_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_t)



/**
 * A 6LoWPAN link table.
 */
typedef struct lowpan_link_table_s
{
    lowpan_link_t MCS51_STORED_IN_RAM *         linkPoolPtr;
    lowpan_link_index_t MCS51_STORED_IN_RAM *   extAddrHashMapPtr;
    lowpan_link_index_t MCS51_STORED_IN_RAM *   shrtAddrHashMapPtr;
    lowpan_link_index_t                         linkPoolLen;
    lowpan_link_index_t                         extAddrHashMapLen;
    lowpan_link_index_t                         shrtAddrHashMapLen;
    lowpan_link_index_t                         firstLinkInPool;
} lowpan_link_table_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_link_table_t)

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_TYPES_H__ */
