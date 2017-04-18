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
#include <ieee154/ucIeee154AddressManipulation.h>



enum
{
    WHIP6_MAX_NUM_MISSED_BROADCASTS_BEFORE_LINK_RESET = 10,
    WHIP6_MAX_NUM_UNACKED_UNICASTS_BEFORE_LINK_RESET = 30,
    WHIP6_MIN_NUM_BROADCASTS_BEFORE_LINK_QUALITY_RECOMPUTATION = 2,
    WHIP6_MIN_NUM_UNICASTS_BEFORE_LINK_QUALITY_RECOMPUTATION = 8,
    WHIP6_LINK_PRR_EWMA_COEFFICIENT_NUMERATOR = 13,
    WHIP6_LINK_PRR_EWMA_COEFFICIENT_DENOMINATOR = 16,
    WHIP6_LINK_ETX_EWMA_COEFFICIENT_NUMERATOR = 14,
    WHIP6_LINK_ETX_EWMA_COEFFICIENT_DENOMINATOR = 16,
    WHIP6_LINK_INITAL_LINK_ETX = (WHIP6_ETX_METRIC_ONE * 4) / 2,
    WHIP6_LINK_EVICTION_ETX = (WHIP6_ETX_METRIC_ONE * 30) / 2,
};


/**
 * Computes a PRR based on the number of received
 * and total number of messages.
 * @param numRecv The number of received messages.
 * @param numTotal The total number of messages.
 * @return The PRR value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX prr_metric_host_t whip6_lowpanMeshLinkTableComputePrrFromNumMessages(
        uint8_t numRecv,
        uint8_t numTotal
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Intergrates two PRR values.
 * @param oldPrr The old PRR value.
 * @param newPrr The new PRR value.
 * @return The integrated PRR value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX prr_metric_host_t whip6_lowpanMeshLinkTableIntegratePrrWithEwma(
        prr_metric_host_t oldPrr,
        prr_metric_host_t newPrr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Intergrates two ETX values.
 * @param oldEtx The old ETX value.
 * @param newEtx The new ETX value.
 * @return The integrated ETX value.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX etx_metric_host_t whip6_lowpanMeshLinkTableIntegrateEtxWithEwma(
        etx_metric_host_t oldEtx,
        etx_metric_host_t newEtx
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



WHIP6_MICROC_INLINE_DEF_PREFIX prr_metric_host_t whip6_lowpanMeshLinkTableComputePrrFromNumMessages(
        uint8_t numRecv,
        uint8_t numTotal
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    prr_sqr_metric_host_t   prr2;

    prr2 = WHIP6_PRR_METRIC_ONE - WHIP6_PRR_METRIC_ZERO;
    prr2 *= numRecv;
    prr2 /= numTotal;
    return (prr_metric_host_t)prr2 + WHIP6_PRR_METRIC_ZERO;
}



WHIP6_MICROC_INLINE_DEF_PREFIX prr_metric_host_t whip6_lowpanMeshLinkTableIntegratePrrWithEwma(
        prr_metric_host_t oldPrr,
        prr_metric_host_t newPrr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    prr_sqr_metric_host_t   oldPrrScaled;
    prr_sqr_metric_host_t   newPrrScaled;

    oldPrrScaled = oldPrr - WHIP6_PRR_METRIC_ZERO;
    oldPrrScaled *= WHIP6_LINK_PRR_EWMA_COEFFICIENT_NUMERATOR;
    newPrrScaled = newPrr - WHIP6_PRR_METRIC_ZERO;
    newPrrScaled *= WHIP6_LINK_PRR_EWMA_COEFFICIENT_DENOMINATOR - WHIP6_LINK_PRR_EWMA_COEFFICIENT_NUMERATOR;
    newPrrScaled += oldPrrScaled;
    newPrrScaled /= WHIP6_LINK_PRR_EWMA_COEFFICIENT_DENOMINATOR;
    return (prr_metric_host_t)newPrrScaled + WHIP6_PRR_METRIC_ZERO;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX etx_metric_host_t whip6_lowpanMeshLinkTableIntegrateEtxWithEwma(
        etx_metric_host_t oldEtx,
        etx_metric_host_t newEtx
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    etx_sqr_metric_host_t   oldEtxScaled;
    etx_sqr_metric_host_t   newEtxScaled;

    oldEtxScaled = oldEtx;
    oldEtxScaled *= WHIP6_LINK_ETX_EWMA_COEFFICIENT_NUMERATOR;
    newEtxScaled = newEtx;
    newEtxScaled *= WHIP6_LINK_ETX_EWMA_COEFFICIENT_DENOMINATOR - WHIP6_LINK_ETX_EWMA_COEFFICIENT_NUMERATOR;
    newEtxScaled += oldEtxScaled;
    newEtxScaled /= WHIP6_LINK_ETX_EWMA_COEFFICIENT_DENOMINATOR;
    return (etx_metric_host_t)newEtxScaled;
}



/**
 * Hashes an extended IEEE 802.15.4 address to
 * a bucket in the link table.
 * @param addr The address to hash.
 * @param numBuckets The number of buckets in the table.
 * @return The bucket number.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableHashExtAddr(
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr,
        lowpan_link_index_t numBuckets
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_index_t   bucketIdx;
    uint8_t               i;
    bucketIdx = 0;
    for (i = 0; i < IEEE154_EXT_ADDR_BYTE_LENGTH; ++i)
    {
        bucketIdx += addr->data[i];
    }
    return bucketIdx % numBuckets;
}



/**
 * Hashes a short IEEE 802.15.4 address to
 * a bucket in the link table.
 * @param addr The address to hash.
 * @param numBuckets The number of buckets in the table.
 * @return The bucket number.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableHashShortAddr(
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr,
        lowpan_link_index_t numBuckets
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_index_t   bucketIdx;
    uint8_t               i;
    bucketIdx = 0;
    for (i = 0; i < IEEE154_SHORT_ADDR_BYTE_LENGTH; ++i)
    {
        bucketIdx += addr->data[i];
    }
    return bucketIdx % numBuckets;
}



/**
 * Removes a given link from the hash table for
 * extended IEEE 802.15.4 addresses.
 * @param table The link table.
 * @param linkPtr The link to be removed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableRemoveFromHashTableForExtAddr(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   prevLink;
    lowpan_link_index_t                   invalidLinkIdx;
    lowpan_link_index_t                   soughtLinkIdx;
    lowpan_link_index_t                   bucketIdx;
    lowpan_link_index_t                   linkIdx;

    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR) == 0)
    {
        return;
    }
    invalidLinkIdx = table->linkPoolLen;
    soughtLinkIdx = linkPtr->idx;
    bucketIdx =
            whip6_lowpanMeshLinkTableHashExtAddr(
                    &linkPtr->extAddr,
                    table->extAddrHashMapLen
            );
    linkIdx = table->extAddrHashMapPtr[bucketIdx];
    prevLink = NULL;
    while (linkIdx != soughtLinkIdx && linkIdx < invalidLinkIdx)
    {
        prevLink = &(table->linkPoolPtr[linkIdx]);
        linkIdx = prevLink->nextExtAddrIdx;
    }
    if (linkIdx >= invalidLinkIdx)
    {
        return;
    }
    if (prevLink == NULL)
    {
        table->extAddrHashMapPtr[bucketIdx] = linkPtr->nextExtAddrIdx;
    }
    else
    {
        prevLink->nextExtAddrIdx = linkPtr->nextExtAddrIdx;
    }
    linkPtr->nextExtAddrIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR;
}



/**
 * Removes a given link from the hash table for
 * short IEEE 802.15.4 addresses.
 * @param table The link table.
 * @param linkPtr The link to be removed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableRemoveFromHashTableForShortAddr(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   prevLink;
    lowpan_link_index_t                   invalidLinkIdx;
    lowpan_link_index_t                   soughtLinkIdx;
    lowpan_link_index_t                   bucketIdx;
    lowpan_link_index_t                   linkIdx;

    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR) == 0)
    {
        return;
    }
    invalidLinkIdx = table->linkPoolLen;
    soughtLinkIdx = linkPtr->idx;
    bucketIdx =
            whip6_lowpanMeshLinkTableHashShortAddr(
                    &linkPtr->shrtAddr,
                    table->shrtAddrHashMapLen
            );
    linkIdx = table->shrtAddrHashMapPtr[bucketIdx];
    prevLink = NULL;
    while (linkIdx != soughtLinkIdx && linkIdx < invalidLinkIdx)
    {
        prevLink = &(table->linkPoolPtr[linkIdx]);
        linkIdx = prevLink->nextShrtAddrIdx;
    }
    if (linkIdx >= invalidLinkIdx)
    {
        return;
    }
    if (prevLink == NULL)
    {
        table->shrtAddrHashMapPtr[bucketIdx] = linkPtr->nextShrtAddrIdx;
    }
    else
    {
        prevLink->nextShrtAddrIdx = linkPtr->nextShrtAddrIdx;
    }
    linkPtr->nextShrtAddrIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR;
}



/**
 * Resets the quality of a given link.
 * @param linkPtr A pointer to the link the quality
 *   of which is to be reset.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableResetLinkQuality(
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    linkPtr->quality.etx = WHIP6_ETX_METRIC_INFINITE;
    linkPtr->quality.lastBeaconSeqNo = 0;
    linkPtr->quality.numReceivedBeacons = 0;
    linkPtr->quality.numMissedBeacons = 0;
    linkPtr->quality.numAckedUnicasts = 0;
    linkPtr->quality.numUnackedUnicasts = 0;
    linkPtr->quality.inPrr = WHIP6_PRR_METRIC_ZERO;
}



/**
 * Recomputes the quality of a given link based
 * on the number of received and missed beacons.
 * @param linkPtr A pointer the to link for which
 *   the quality is to be recomputed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableRecomputeBeaconBasedLinkQualityIfNecessary(
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t   numBeaconsReceived;
    uint8_t   numBeaconsTotal;

    numBeaconsReceived = linkPtr->quality.numReceivedBeacons;
    numBeaconsTotal = numBeaconsReceived + linkPtr->quality.numMissedBeacons;
    if (numBeaconsTotal < WHIP6_MIN_NUM_BROADCASTS_BEFORE_LINK_QUALITY_RECOMPUTATION)
    {
        return;
    }
    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_INIT) != 0)
    {
        linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_INIT;
        linkPtr->quality.etx = WHIP6_LINK_INITAL_LINK_ETX;
        linkPtr->quality.inPrr = whip6_metricEtxToPrr(WHIP6_LINK_INITAL_LINK_ETX);
    }
    linkPtr->quality.inPrr =
            whip6_lowpanMeshLinkTableIntegratePrrWithEwma(
                    linkPtr->quality.inPrr,
                    whip6_lowpanMeshLinkTableComputePrrFromNumMessages(
                            numBeaconsReceived,
                            numBeaconsTotal
                    )
            );
    linkPtr->quality.etx =
            whip6_lowpanMeshLinkTableIntegrateEtxWithEwma(
                    linkPtr->quality.etx,
                    whip6_metricPrrToEtx(linkPtr->quality.inPrr)
            );
    linkPtr->quality.numReceivedBeacons = 0;
    linkPtr->quality.numMissedBeacons = 0;
}



/**
 * Recomputes the quality of a given link based
 * on the number of received and missed acknowledgments.
 * @param linkPtr A pointer the to link for which
 *   the quality is to be recomputed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableRecomputeAckBasedLinkQualityIfNecessary(
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    etx_metric_host_t   newEtxEstimate;
    uint8_t             numAckedUnicasts;
    uint8_t             numTotalUnicasts;

    numAckedUnicasts = linkPtr->quality.numAckedUnicasts;
    numTotalUnicasts = numAckedUnicasts + linkPtr->quality.numUnackedUnicasts;
    if (numTotalUnicasts < WHIP6_MIN_NUM_UNICASTS_BEFORE_LINK_QUALITY_RECOMPUTATION ||
            (linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_INIT) != 0)
    {
        return;
    }
    if (numAckedUnicasts == 0)
    {
        newEtxEstimate = numTotalUnicasts + 1;
        newEtxEstimate *= WHIP6_ETX_METRIC_ONE;
        // Do not reset the counter.
    }
    else
    {
        newEtxEstimate = numTotalUnicasts;
        newEtxEstimate *= WHIP6_ETX_METRIC_ONE;
        newEtxEstimate /= numAckedUnicasts;
        linkPtr->quality.numAckedUnicasts = 0;
        linkPtr->quality.numUnackedUnicasts = 0;
    }
    linkPtr->quality.etx =
            whip6_lowpanMeshLinkTableIntegrateEtxWithEwma(
                    linkPtr->quality.etx == WHIP6_ETX_METRIC_INFINITE ?
                            WHIP6_LINK_INITAL_LINK_ETX : linkPtr->quality.etx,
                    newEtxEstimate
            );
}


WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableResetMACState(
        lowpan_link_t MCS51_STORED_IN_RAM * linkPtr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    linkPtr->mac.lastBeaconTimestamp = WHIP6_6LOWPAN_MAC_EMPTY_TIMESTAMP;
    linkPtr->mac.driftBeaconTimestamp = WHIP6_6LOWPAN_MAC_EMPTY_TIMESTAMP;
    linkPtr->mac.driftCompensation = WHIP6_6LOWPAN_MAC_NO_COMPENSATION_DATA;
}


/**
 * Allocates a link with a short IEEE 802.15.4
 * address. It is assumed that the pool contains
 * a free link to allocate.
 * @param table The link table.
 * @param addr The address.
 * @return The index of the allocated link.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableAllocateLinkForShortAddr(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    lowpan_link_index_t                   linkIdx;
    lowpan_link_index_t                   bucketIdx;

    linkIdx = table->firstLinkInPool;
    linkPtr = &(table->linkPoolPtr[linkIdx]);
    table->firstLinkInPool = linkPtr->nextExtAddrIdx;
    linkPtr->flags = WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR;
    whip6_ieee154AddrShortCpy(addr, &linkPtr->shrtAddr);
    bucketIdx = whip6_lowpanMeshLinkTableHashShortAddr(addr, table->shrtAddrHashMapLen);
    linkPtr->nextShrtAddrIdx = table->shrtAddrHashMapPtr[bucketIdx];
    table->shrtAddrHashMapPtr[bucketIdx] = linkIdx;
    linkPtr->nextExtAddrIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    whip6_lowpanMeshLinkTableResetLinkQuality(linkPtr);
    whip6_lowpanMeshLinkTableResetMACState(linkPtr);
    return linkIdx;
}



/**
 * Allocates a link with an extended IEEE 802.15.4
 * address. It is assumed that the pool contains
 * a free link to allocate.
 * @param table The link table.
 * @param addr The address.
 * @return The index of the allocated link.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableAllocateLinkForExtAddr(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    lowpan_link_index_t                   linkIdx;
    lowpan_link_index_t                   bucketIdx;

    linkIdx = table->firstLinkInPool;
    linkPtr = &(table->linkPoolPtr[linkIdx]);
    table->firstLinkInPool = linkPtr->nextExtAddrIdx;
    linkPtr->flags = WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR;
    whip6_ieee154AddrExtCpy(addr, &linkPtr->extAddr);
    bucketIdx = whip6_lowpanMeshLinkTableHashExtAddr(addr, table->extAddrHashMapLen);
    linkPtr->nextExtAddrIdx = table->extAddrHashMapPtr[bucketIdx];
    table->extAddrHashMapPtr[bucketIdx] = linkIdx;
    linkPtr->nextShrtAddrIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    whip6_lowpanMeshLinkTableResetLinkQuality(linkPtr);
    whip6_lowpanMeshLinkTableResetMACState(linkPtr);
    return linkIdx;
}



/**
 * Tries to evict a link from a link table.
 * @param table The link table.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableTryToEvictWorstLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;
    etx_metric_host_t                           worstEtx;
    lowpan_link_index_t                         worstIdx;
    lowpan_link_index_t                         numLinks;

    // printf("Trying to evict worst link\n\r");
    worstEtx = WHIP6_ETX_METRIC_ZERO;
    worstIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    linkPtr = &(table->linkPoolPtr[0]);
    numLinks = table->linkPoolLen;
    for (; numLinks > 0; --numLinks)
    {
        // printf("Link: %u; flags: %u; etx: %u\n\r", (unsigned)linkPtr->idx, (unsigned)linkPtr->flags, (unsigned)linkPtr->quality.etx);
        if (whip6_lowpanMeshLinkTableCanExistingLinkBeRemovedInternal(linkPtr))
        {
            etx_metric_host_t   currEtx;
            currEtx = linkPtr->quality.etx;
            if (worstEtx < currEtx)
            {
                worstEtx = currEtx;
                worstIdx = linkPtr->idx;
            }
        }
        ++linkPtr;
    }
    if (worstIdx == WHIP6_6LOWPAN_INVALID_LINK_IDX)
    {
        return;
    }
    // printf("Selected %u for removal.\n\r", (unsigned)worstIdx);
    whip6_lowpanMeshLinkTableRemoveExistingLink(table, worstIdx);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanMeshLinkTableReset(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *         linkPtr;
    lowpan_link_index_t MCS51_STORED_IN_RAM *   hashPtr;
    lowpan_link_index_t                         idx;
    lowpan_link_index_t                         num;

    num = table->linkPoolLen;
    if (num > 0)
    {
        linkPtr = table->linkPoolPtr;
        --num;
        for (idx = 0; idx < num; ++idx)
        {
            linkPtr->idx = idx;
            linkPtr->flags = 0;
            linkPtr->nextExtAddrIdx = idx + 1;
            ++linkPtr;
        }
        linkPtr->idx = num;
        linkPtr->flags = 0;
        linkPtr->nextExtAddrIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
        table->firstLinkInPool = 0;
    }
    else
    {
        table->firstLinkInPool = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    }

    hashPtr = table->extAddrHashMapPtr;
    for (num = table->extAddrHashMapLen; num > 0; --num)
    {
        *hashPtr = WHIP6_6LOWPAN_INVALID_LINK_IDX;
        ++hashPtr;
    }

    hashPtr = table->shrtAddrHashMapPtr;
    for (num = table->shrtAddrHashMapLen; num > 0; --num)
    {
        *hashPtr = WHIP6_6LOWPAN_INVALID_LINK_IDX;
        ++hashPtr;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableLookupLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_index_t   linkIdx;
    lowpan_link_index_t   invalidLinkIdx;

    invalidLinkIdx = table->linkPoolLen;
    if (addr->mode == IEEE154_ADDR_MODE_SHORT)
    {
        linkIdx =
                whip6_lowpanMeshLinkTableHashShortAddr(
                        &addr->vars.shrt,
                        table->shrtAddrHashMapLen
                );
        linkIdx = table->shrtAddrHashMapPtr[linkIdx];
        while (linkIdx < invalidLinkIdx)
        {
            lowpan_link_t MCS51_STORED_IN_RAM const *   link;
            link = &(table->linkPoolPtr[linkIdx]);
            if (whip6_ieee154AddrShortCmp(&addr->vars.shrt, &link->shrtAddr) == 0)
            {
                break;
            }
            linkIdx = link->nextShrtAddrIdx;
        }
    }
    else if (addr->mode == IEEE154_ADDR_MODE_EXT)
    {
        linkIdx =
                whip6_lowpanMeshLinkTableHashExtAddr(
                        &addr->vars.ext,
                        table->extAddrHashMapLen
                );
        linkIdx = table->extAddrHashMapPtr[linkIdx];
        while (linkIdx < invalidLinkIdx)
        {
            lowpan_link_t MCS51_STORED_IN_RAM const *   link;
            link = &(table->linkPoolPtr[linkIdx]);
            if (whip6_ieee154AddrExtCmp(&addr->vars.ext, &link->extAddr) == 0)
            {
                break;
            }
            linkIdx = link->nextExtAddrIdx;
        }
    }
    else
    {
        linkIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    }
    return linkIdx >= invalidLinkIdx ? WHIP6_6LOWPAN_INVALID_LINK_IDX : linkIdx;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableFindExistingOrCreateNewLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr,
        uint8_t allowEviction
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_index_t                   linkIdx;

    linkIdx = whip6_lowpanMeshLinkTableLookupLink(table, addr);
    if (linkIdx != WHIP6_6LOWPAN_INVALID_LINK_IDX)
    {
        return linkIdx;
    }

    if (table->firstLinkInPool == WHIP6_6LOWPAN_INVALID_LINK_IDX)
    {
        if (allowEviction)
        {
            whip6_lowpanMeshLinkTableTryToEvictWorstLink(table);
            if (table->firstLinkInPool == WHIP6_6LOWPAN_INVALID_LINK_IDX)
            {
                return WHIP6_6LOWPAN_INVALID_LINK_IDX;
            }
        }
        else
        {
            return WHIP6_6LOWPAN_INVALID_LINK_IDX;
        }
    }
    if (addr->mode == IEEE154_ADDR_MODE_SHORT)
    {
        linkIdx =
                whip6_lowpanMeshLinkTableAllocateLinkForShortAddr(
                        table,
                        &addr->vars.shrt
                );
    }
    else if (addr->mode == IEEE154_ADDR_MODE_EXT)
    {
        linkIdx =
                whip6_lowpanMeshLinkTableAllocateLinkForExtAddr(
                        table,
                        &addr->vars.ext
                );
    }
    else
    {
        linkIdx = WHIP6_6LOWPAN_INVALID_LINK_IDX;
    }
    return linkIdx;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanMeshLinkTableRemoveExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;

    if (index >= table->linkPoolLen)
    {
        return;
    }
    linkPtr = &(table->linkPoolPtr[index]);
    if (! whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(linkPtr))
    {
        return;
    }
    whip6_lowpanMeshLinkTableRemoveFromHashTableForExtAddr(table, linkPtr);
    whip6_lowpanMeshLinkTableRemoveFromHashTableForShortAddr(table, linkPtr);
    linkPtr->flags = 0;
    linkPtr->nextExtAddrIdx = table->firstLinkInPool;
    table->firstLinkInPool = index;
    // printf("Removed %u\n\r", (unsigned)index);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableGetFirstLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    lowpan_link_index_t                   num;

    linkPtr = &(table->linkPoolPtr[0]);
    for (num = table->linkPoolLen; num > 0; --num)
    {
        if (whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(linkPtr))
        {
            return linkPtr->idx;
        }
        ++linkPtr;
    }
    return WHIP6_6LOWPAN_INVALID_LINK_IDX;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_link_index_t whip6_lowpanMeshLinkTableGetNextLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    lowpan_link_index_t                   num;

    num = table->linkPoolLen;
    if (index >= num)
    {
        return WHIP6_6LOWPAN_INVALID_LINK_IDX;
    }
    ++index;
    linkPtr = &(table->linkPoolPtr[index]);
    for (num -= index; num > 0; --num)
    {
        if (whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(linkPtr))
        {
            return linkPtr->idx;
        }
        ++linkPtr;
    }
    return WHIP6_6LOWPAN_INVALID_LINK_IDX;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanMeshLinkTableReportBroadcastReceptionForExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index,
        lowpan_header_bc0_seq_no_t seqNo
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    uint8_t                               numMissedBeacons;

    linkPtr = &(table->linkPoolPtr[index]);
    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_INIT) == 0 &&
            linkPtr->quality.etx >= WHIP6_ETX_METRIC_INFINITE)
    {
        linkPtr->flags |= WHIP6_6LOWPAN_LINK_FLAG_INIT;
        linkPtr->quality.lastBeaconSeqNo = seqNo - 1;
    }
    numMissedBeacons = seqNo - linkPtr->quality.lastBeaconSeqNo - 1;
    if (numMissedBeacons > WHIP6_MAX_NUM_MISSED_BROADCASTS_BEFORE_LINK_RESET)
    {
        whip6_lowpanMeshLinkTableResetLinkQuality(linkPtr);
        linkPtr->flags &=
                (WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR |
                        WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR |
                        WHIP6_6LOWPAN_LINK_FLAG_PINNED);
        linkPtr->flags |= WHIP6_6LOWPAN_LINK_FLAG_INIT;
        linkPtr->quality.numReceivedBeacons = 1;
    }
    else
    {
        linkPtr->quality.numReceivedBeacons++;
        linkPtr->quality.numMissedBeacons += numMissedBeacons;
    }
    whip6_lowpanMeshLinkTableRecomputeBeaconBasedLinkQualityIfNecessary(linkPtr);
    linkPtr->quality.lastBeaconSeqNo = seqNo;
    linkPtr->flags |= WHIP6_6LOWPAN_LINK_FLAG_REFRESHED;
    linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_RECLAIMABLE;
    // printf("idx=%u;ptr=%lu;flags=%u;etx=%u;seqNo=%u\r\n", (unsigned)index,
    //         (long unsigned)linkPtr, (unsigned)linkPtr->flags,
    //         (unsigned)linkPtr->quality.etx, (unsigned)linkPtr->quality.lastBeaconSeqNo);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanMeshLinkTableReportUnicastCompletionForExistingLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index,
        uint8_t acked
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;

    linkPtr = &(table->linkPoolPtr[index]);
    if (acked)
    {
        ++linkPtr->quality.numAckedUnicasts;
        linkPtr->flags |= WHIP6_6LOWPAN_LINK_FLAG_REFRESHED;
        linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_RECLAIMABLE;
    }
    else
    {
        ++linkPtr->quality.numUnackedUnicasts;
        if (linkPtr->quality.numUnackedUnicasts > WHIP6_MAX_NUM_UNACKED_UNICASTS_BEFORE_LINK_RESET)
        {
            linkPtr->quality.etx = WHIP6_ETX_METRIC_INFINITE;
            linkPtr->quality.numAckedUnicasts = 0;
            linkPtr->quality.numUnackedUnicasts = 0;
            return;
        }
    }
    whip6_lowpanMeshLinkTableRecomputeAckBasedLinkQualityIfNecessary(linkPtr);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_lowpanMeshLinkTableMarkUnrefreshedLinksForRemoval(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t firstIdx,
        lowpan_link_index_t numIdx
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    uint8_t                               res;

    numIdx += firstIdx;
    if (firstIdx >= table->linkPoolLen)
    {
        return 0;
    }
    if (numIdx >= table->linkPoolLen)
    {
        numIdx = table->linkPoolLen;
        res = 0;
    }
    else
    {
        res = 1;
    }
    numIdx -= firstIdx;
    linkPtr = &(table->linkPoolPtr[firstIdx]);
    for (; numIdx > 0; --numIdx)
    {
        if (whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(linkPtr))
        {
            if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_REFRESHED) == 0)
            {
                linkPtr->flags |= WHIP6_6LOWPAN_LINK_FLAG_RECLAIMABLE;
            }
            else
            {
                linkPtr->flags &= ~WHIP6_6LOWPAN_LINK_FLAG_REFRESHED;
            }
        }
        ++linkPtr;
    }
    return res;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_lowpanMeshLinkTableRemoveLinksMarkedForRemoval(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t firstIdx,
        lowpan_link_index_t numIdx,
        lowpan_link_index_t maxRemoved
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *   linkPtr;
    uint8_t                               res;

    numIdx += firstIdx;
    if (firstIdx >= table->linkPoolLen)
    {
        return 0;
    }
    if (numIdx >= table->linkPoolLen)
    {
        numIdx = table->linkPoolLen;
        res = 0;
    }
    else
    {
        res = 1;
    }
    numIdx -= firstIdx;
    linkPtr = &(table->linkPoolPtr[firstIdx]);
    for (; numIdx > 0 && maxRemoved > 0; --numIdx)
    {
        if (whip6_lowpanMeshLinkTableCanExistingLinkBeRemovedInternal(linkPtr) &&
                (linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_RECLAIMABLE) != 0)
        {
            whip6_lowpanMeshLinkTableRemoveExistingLink(table, linkPtr->idx);
            --maxRemoved;
        }
        ++linkPtr;
    }
    return res;
}

/**
 * Returns MAC pointer to the MAC state for this link.
 * @param table The table.
 * @param idx The index of the link. Must be valid.
 * @return A pointer to the MAC state.
 */
WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_link_mac_state_t MCS51_STORED_IN_RAM *whip6_lowpanMeshLinkTableGetMACStateForLink(
        lowpan_link_table_t MCS51_STORED_IN_RAM * table,
        lowpan_link_index_t index
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM *linkPtr = &(table->linkPoolPtr[index]);
    return &linkPtr->mac;
}
