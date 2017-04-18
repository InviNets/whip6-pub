/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_MESH_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_MESH_MANIPULATION_IMPL_H__


#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_MESH_MANIPULATION_H__ */


WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(
        lowpan_link_t MCS51_STORED_IN_RAM const * linkPtr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_lowpanMeshLinkTableCanExistingLinkBeRemovedInternal(
        lowpan_link_t MCS51_STORED_IN_RAM const * linkPtr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(
        lowpan_link_t MCS51_STORED_IN_RAM const * linkPtr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return (linkPtr->flags & (WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR | WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR)) != 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_lowpanMeshLinkTableCanExistingLinkBeRemoved(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t linkIdx
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;

    linkPtr = &(table->linkPoolPtr[linkIdx]);
    return whip6_lowpanMeshLinkTableCanExistingLinkBeRemovedInternal(linkPtr);
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_lowpanMeshLinkTableCanExistingLinkBeRemovedInternal(
        lowpan_link_t MCS51_STORED_IN_RAM const * linkPtr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_lowpanMeshLinkTableIsLinkAllocatedInternal(linkPtr) &&
            (linkPtr->flags & (WHIP6_6LOWPAN_LINK_FLAG_INIT | WHIP6_6LOWPAN_LINK_FLAG_PINNED)) == 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX etx_metric_host_t whip6_lowpanMeshLinkTableGetLinkEtx(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t linkIdx
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;

    linkPtr = &(table->linkPoolPtr[linkIdx]);
    return linkPtr->quality.etx;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_ext_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanMeshLinkTableGetLinkAddrExtPtr(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t linkIdx
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;

    linkPtr = &(table->linkPoolPtr[linkIdx]);
    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_HAS_EXT_ADDR) == 0)
    {
        return NULL;
    }
    return &linkPtr->extAddr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_short_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanMeshLinkTableGetLinkAddrShortPtr(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t linkIdx
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;

    linkPtr = &(table->linkPoolPtr[linkIdx]);
    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR) == 0)
    {
        return NULL;
    }
    return &linkPtr->shrtAddr;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanMeshLinkTableGetLinkAddrBest(
        lowpan_link_table_t MCS51_STORED_IN_RAM const * table,
        lowpan_link_index_t linkIdx,
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_link_t MCS51_STORED_IN_RAM const *   linkPtr;

    linkPtr = &(table->linkPoolPtr[linkIdx]);
    if ((linkPtr->flags & WHIP6_6LOWPAN_LINK_FLAG_HAS_SHORT_ADDR) != 0)
    {
        addr->mode = IEEE154_ADDR_MODE_SHORT;
        whip6_shortMemCpy(
                &(linkPtr->shrtAddr.data[0]),
                &(addr->vars.shrt.data[0]),
                IEEE154_SHORT_ADDR_BYTE_LENGTH
        );
    }
    else
    {
        addr->mode = IEEE154_ADDR_MODE_EXT;
        whip6_shortMemCpy(
                &(linkPtr->extAddr.data[0]),
                &(addr->vars.ext.data[0]),
                IEEE154_EXT_ADDR_BYTE_LENGTH
        );
    }
}



#endif /* __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_MESH_MANIPULATION_IMPL_H__ */
