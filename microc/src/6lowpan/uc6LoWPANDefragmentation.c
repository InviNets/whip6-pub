/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANDefragmentation.h>
#include <6lowpan/uc6LoWPANHeaderManipulation.h>
#include <6lowpan/uc6LoWPANIpv6HeaderCompression.h>
#include <base/ucError.h>
#include <base/ucString.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154FrameManipulation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>


/**
 * Destroys all fragment specifications of a packet.
 * @param state The defragmenter state.
 * @param defragPacket The packet of which the
 *   fragment specifications are to be destroyed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanDefragmenterDestroyFragSpecsOfPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * defragPacket
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *   currFragSpec;
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *   prevFragSpec;

    prevFragSpec = NULL;
    currFragSpec = defragPacket->firstFragSpec.next;
    while (currFragSpec != NULL)
    {
        prevFragSpec = currFragSpec;
        currFragSpec = currFragSpec->next;
    }
    if (prevFragSpec != NULL)
    {
        prevFragSpec->next = state->freeAdditionalFragSpecs;
        state->freeAdditionalFragSpecs = defragPacket->firstFragSpec.next;
        defragPacket->firstFragSpec.next = NULL;
    }
}



/**
 * Destroys the packet and adds it to the
 * list of free packets. It is assumed that
 * the packet does not belong to any other list.
 * @param state The defragmenter state.
 * @param defragPacket The packet to be destroyed.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanDefragmenterDestroyDefragPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * defragPacket
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{

    // Free the packet I/O vector.
    if (defragPacket->packet != NULL)
    {
        whip6_ipv6FreePacket(defragPacket->packet);
        defragPacket->packet = NULL;
    }
    // Free the additional fragment specifications.
    whip6_lowpanDefragmenterDestroyFragSpecsOfPacket(state, defragPacket);
    // Append the defragmented packets to the free list.
    defragPacket->next = state->freePackets;
    state->freePackets = defragPacket;
}



/**
 * Unlocks a defragmented packet.
 * @param state The defragmenter state.
 * @param lockedDefragPacket The packet
 *   to be unlocked.
 * @return Zero if the packet has been unlocked,
 *   or non-zero if it does not exist on the locked
 *   packet list.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanDefragmenterUnlockDefragPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * currDefragPacket;
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * prevDefragPacket;

    prevDefragPacket = NULL;
    currDefragPacket = state->lockedPackets;
    while (currDefragPacket != NULL && currDefragPacket != lockedDefragPacket)
    {
        prevDefragPacket = currDefragPacket;
        currDefragPacket = currDefragPacket->next;
    }
    if (currDefragPacket == NULL)
    {
        return 1;
    }
    if (prevDefragPacket == NULL)
    {
        state->lockedPackets = currDefragPacket->next;
    }
    else
    {
        prevDefragPacket->next = currDefragPacket->next;
    }
    lockedDefragPacket->next = NULL;
    return 0;
}



/**
 * Searches for the first fragment AFTER which the
 * given fragment specification should be appended.
 * @param defragPacket The packet the fragments
 *   of which should be considered.
 * @param newFragOff The offset of the new fragment.
 * @return A pointer to the fragment specification.
 *   NULL denotes that the fragment should be the
 *   first fragment.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterFindWhereNewFragSpecShouldBeInserted(
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * defragPacket,
        lowpan_header_frag_dgram_offset_t newFragOff
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * prevFragSpec;
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * currFragSpec;

    prevFragSpec = NULL;
    currFragSpec = &defragPacket->firstFragSpec;
    do
    {
        if (newFragOff <= currFragSpec->offset)
        {
            break;
        }
        prevFragSpec = currFragSpec;
        currFragSpec = currFragSpec->next;
    }
    while (currFragSpec != NULL);
    return prevFragSpec;
}



/**
 * Attempts to concatenate a new fragment specification
 * with an existing one.
 * @param fragSpec An existing fragment specification.
 * @param newFragOff The offset of the new fragment.
 * @param newFragLen The length of the new fragment.
 * @param identicalContent Nonzero if copying the content
 *   of the new fragment into the packet revealed that
 *   both the old packet fragment and the new one have
 *   the same content; zero otherwise.
 * @return Zero if the concatenation succeeded, a positive
 *   value if the fragments cannot be concatenated, but
 *   overlap, or a negative value otherwise.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX int8_t whip6_lowpanDefragmenterConcatenateNewFragSpecWithExistingOne(
        lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * fragSpec,
        lowpan_header_frag_dgram_offset_t newFragOff,
        lowpan_header_frag_dgram_size_t newFragLen,
        uint8_t identicalContent
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_header_frag_dgram_offset_t   newStart;
    lowpan_header_frag_dgram_offset_t   newEnd;
    lowpan_header_frag_dgram_size_t     newSize;
    lowpan_header_frag_dgram_size_t     sumSize;
    uint8_t                             contained;

    newStart = fragSpec->offset;
    sumSize = fragSpec->size;
    newEnd = newStart + sumSize;
    sumSize += newFragLen;
    contained = 1;
    if (newStart > newFragOff)
    {
        newStart = newFragOff;
        contained = 0;
    }
    if (newEnd < newFragOff + newFragLen)
    {
        newEnd = newFragOff + newFragLen;
        contained = 0;
    }
    newSize = newEnd - newStart;
    if (newSize == sumSize)
    {
        // Merged.
        fragSpec->offset = newStart;
        fragSpec->size = newSize;
        return 0;
    }
    else if (newSize > sumSize)
    {
        // Disjoint.
        return (int8_t)(-1);
    }
    else
    {
        // Overlapping.
        return contained && identicalContent ? 0 : (int8_t)1;
    }
}



/**
 * Attempts to concatenate a given fragment specification
 * with the next one on the list (if the next one exists).
 * @param fragSpec An existing fragment specification.
 * @param newFragOff The offset of the new fragment.
 * @param newFragLen The length of the new fragment.
 * @param identicalContent Nonzero if copying the content
 *   of the new fragment into the packet revealed that
 *   both the old packet fragment and the new one have
 *   the same content; zero otherwise.
 * @return Zero if the concatenation succeeded, a positive
 *   value if the fragments cannot be concatenated, but
 *   overlap, or a negative value otherwise.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_lowpanDefragmenterTryToConcatenateFragSpecWithNextOnList(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * fragSpec,
        uint8_t identicalContent
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *   nextFragSpec;
    int8_t                                            concatenationResult;

    nextFragSpec = fragSpec->next;
    if (nextFragSpec != NULL)
    {
        concatenationResult =
                whip6_lowpanDefragmenterConcatenateNewFragSpecWithExistingOne(
                        fragSpec,
                        nextFragSpec->offset,
                        nextFragSpec->size,
                        identicalContent
                );
        if (concatenationResult == 0)
        {
            // We are good, because we managed
            // to concatenate adjacent specs.
            fragSpec->next = nextFragSpec->next;
            nextFragSpec->next = state->freeAdditionalFragSpecs;
            state->freeAdditionalFragSpecs = nextFragSpec;
        }
        else if (concatenationResult > 0)
        {
            // Ups, we have an overlap. What
            // should we leave, what should we drop?
            // Let's simply drop whatever remains
            // of the packet, but leave what
            // we managed to concatenate.
            while (nextFragSpec->next != NULL)
            {
                nextFragSpec = nextFragSpec->next;
            }
            nextFragSpec->next = state->freeAdditionalFragSpecs;
            state->freeAdditionalFragSpecs = fragSpec->next;
            fragSpec->next = NULL;
        }
        // else we do not care.
    }
}



/**
 * Attempts to merge a new fragment specification
 * with the specifications that are already available
 * for a defragmented packet. It is assumed that the
 * new specification has a nonzero length and
 * fits into the packet.
 * @param state The defragmenter state.
 * @param defragPacket The defragmented packet.
 * @param prevFragSpec An existing specification
 *   AFTER which the new one should be merged, or
 *   NULL if the new specification is the first
 *   to appear on the list.
 * @param newFragOff The offset of the new fragment.
 * @param newFragLen The length of the new fragment.
 * @param identicalContent Nonzero if copying the content
 *   of the new fragment into the packet revealed that
 *   both the old packet fragment and the new one have
 *   the same content; zero otherwise.
 * @return Zero if merging has been successful, or
 *   nonzero if a fatal error occurred and the
 *   entire packet should be dropped.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_lowpanDefragmenterMergeNewFragSpecIntoPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * defragPacket,
        lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * prevFragSpec,
        lowpan_header_frag_dgram_offset_t newFragOff,
        lowpan_header_frag_dgram_size_t newFragLen,
        uint8_t identicalContent
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *   nextFragSpec;
    int8_t                                            concatenationResult;

    if (newFragOff == 0)
    {
        // We are dealing with the first fragment,
        // so we always try to concatenate its spec
        // with the first spec on the list.
        concatenationResult =
                whip6_lowpanDefragmenterConcatenateNewFragSpecWithExistingOne(
                        &defragPacket->firstFragSpec,
                        newFragOff,
                        newFragLen,
                        identicalContent
                );
        // printf("AAA concatenation %u\n\r", (unsigned)concatenationResult);
        if (concatenationResult != 0)
        {
            // Even if the concatenation fails
            // (due to overlapping or disjoint
            // fragments), we simply recreate the packet.
            whip6_lowpanDefragmenterDestroyFragSpecsOfPacket(state, defragPacket);
            defragPacket->firstFragSpec.offset = 0;
            defragPacket->firstFragSpec.size = newFragLen;
        }
        else
        {
            // We have managed to concatenate the fragments.
            // We may be able to concatenate the next one.
            whip6_lowpanDefragmenterTryToConcatenateFragSpecWithNextOnList(
                    state,
                    &defragPacket->firstFragSpec,
                    identicalContent
            );
        }
        return 0;
    }
    else
    {
        if (prevFragSpec == NULL)
        {
            // Something is seriously wrong:
            // we got a fragment that is not
            // first, but there is no previous
            // fragment for it.
            return 1;
        }
        concatenationResult =
                whip6_lowpanDefragmenterConcatenateNewFragSpecWithExistingOne(
                        prevFragSpec,
                        newFragOff,
                        newFragLen,
                        identicalContent
                );
        // printf("BBB concatenation %u\n\r", (unsigned)concatenationResult);
        if (concatenationResult == 0)
        {
            // We have managed to concatenate the fragments.
            // We may be able to concatenate the next one.
            whip6_lowpanDefragmenterTryToConcatenateFragSpecWithNextOnList(
                    state,
                    prevFragSpec,
                    identicalContent
            );
            return 0;
        }
        else if (concatenationResult > 0)
        {
            // We have an overlap, so we have to
            // deal with it, by dropping the
            // entire packet.
            whip6_lowpanDefragmenterDestroyFragSpecsOfPacket(state, defragPacket);
            nextFragSpec = state->freeAdditionalFragSpecs;
            if (nextFragSpec == NULL)
            {
                // Ups, we are screwed, we cannot start
                // a new packet in the middle, because
                // there are no free specs to allocate.
                // Well, nothing to do but report that
                // the entire packet should be dropped.
                return 1;
            }
            state->freeAdditionalFragSpecs = nextFragSpec->next;
            nextFragSpec->offset = newFragOff;
            nextFragSpec->size = newFragLen;
            nextFragSpec->next = NULL;
            defragPacket->firstFragSpec.offset = 0;
            defragPacket->firstFragSpec.size = 0;
            defragPacket->firstFragSpec.next = nextFragSpec;
            return 0;
        }
        else
        {
            // We have a disjoin set, so we may
            // try the next spec if it exists.
            nextFragSpec = prevFragSpec->next;
            if (nextFragSpec != NULL)
            {
                // The next spec exists, so
                // try to concatenate with it.
                concatenationResult =
                        whip6_lowpanDefragmenterConcatenateNewFragSpecWithExistingOne(
                                nextFragSpec,
                                newFragOff,
                                newFragLen,
                                identicalContent
                        );
                // printf("CCC concatenation %u\n\r", (unsigned)concatenationResult);
                if (concatenationResult < 0)
                {
                    // We are disjoint, so we have to allocate
                    // a new frame.
                    nextFragSpec = state->freeAdditionalFragSpecs;
                    if (nextFragSpec == NULL)
                    {
                        // Well, nothing we can do here,
                        // because we have no memory left.
                        return 1;
                    }
                    state->freeAdditionalFragSpecs = nextFragSpec->next;
                    nextFragSpec->next = prevFragSpec->next;
                    prevFragSpec->next = nextFragSpec;
                    nextFragSpec->offset = newFragOff;
                    nextFragSpec->size = newFragLen;
                }
                else if (concatenationResult > 0)
                {
                    // Ups, we have an overlap. What
                    // should we leave, what should we drop?
                    // Let's simply drop whatever remains
                    // of the packet, but leave what
                    // we managed to concatenate at the
                    // beginning.
                    while (nextFragSpec->next != NULL)
                    {
                        nextFragSpec = nextFragSpec->next;
                    }
                    nextFragSpec->next = state->freeAdditionalFragSpecs;
                    state->freeAdditionalFragSpecs = prevFragSpec->next;
                    prevFragSpec->next = NULL;
                    nextFragSpec = state->freeAdditionalFragSpecs;
                    if (nextFragSpec == NULL)
                    {
                        // Well, nothing we can do here,
                        // because we have no memory left.
                        return 1;
                    }
                    state->freeAdditionalFragSpecs = nextFragSpec->next;
                    prevFragSpec->next = nextFragSpec;
                    nextFragSpec->offset = newFragOff;
                    nextFragSpec->size = newFragLen;
                    nextFragSpec->next = NULL;
                }
                // else we managed to concatenate, so
                // we do not care anymore.
                return 0;
            }
            else
            {
                // The next spec does not exist,
                // so we have to allocate one.
                nextFragSpec = state->freeAdditionalFragSpecs;
                if (nextFragSpec == NULL)
                {
                    // Well, nothing we can do here,
                    // because we have no memory left.
                    return 1;
                }
                state->freeAdditionalFragSpecs = nextFragSpec->next;
                prevFragSpec->next = nextFragSpec;
                nextFragSpec->offset = newFragOff;
                nextFragSpec->size = newFragLen;
                nextFragSpec->next = NULL;
                return 0;
            }
        }
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanDefragmenterInit(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * pktsArrPtr,
        lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * fragSpecArrPtr,
        uint8_t pktsArrLen,
        uint8_t fragSpecArrLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    state->currentPackets = NULL;
    state->lockedPackets = NULL;
    if (pktsArrLen > 0 && pktsArrPtr != NULL)
    {
        state->freePackets = pktsArrPtr;
        --pktsArrLen;
        while (pktsArrLen > 0)
        {
            lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * tmp = pktsArrPtr;
            ++pktsArrPtr;
            tmp->next = pktsArrPtr;
            --pktsArrLen;
        }
        pktsArrPtr->next = NULL;
    }
    else
    {
        state->freePackets = NULL;
    }
    if (fragSpecArrLen > 0 && fragSpecArrPtr != NULL)
    {
        state->freeAdditionalFragSpecs = fragSpecArrPtr;
        --fragSpecArrLen;
        while (fragSpecArrLen > 0)
        {
            lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * tmp = fragSpecArrPtr;
            ++fragSpecArrPtr;
            tmp->next = fragSpecArrPtr;
            --fragSpecArrLen;
        }
        fragSpecArrPtr->next = NULL;
    }
    else
    {
        state->freeAdditionalFragSpecs = NULL;
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanDefragmenterCreateVirtualMeshHeaderIfNecessary(
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM * lowpanHdrs
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (! whip6_lowpanFrameHeadersHasMeshHeader(lowpanHdrs))
    {
        // If we do not have a fragmentation header, copy
        // addresses from the IEEE 802.15.4 frame header.
        whip6_ieee154DFrameGetDstAddr(
                frameInfo,
                whip6_lowpanFrameHeadersGetMeshHeaderDstAddrPtr(lowpanHdrs)
        );
        whip6_ieee154DFrameGetSrcAddr(
                frameInfo,
                whip6_lowpanFrameHeadersGetMeshHeaderSrcAddrPtr(lowpanHdrs)
        );
        whip6_lowpanFrameHeadersSetMeshHeaderHopLimit(
                lowpanHdrs,
                1
        );
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterFindExistingOrAllocateNewPacketAndLockIt(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs,
        defrag_time_in_ms_t currTimeInMs
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   currFragPacket;
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   prevFragPacket;

    if (whip6_ieee154DFrameIsInterPan(frameInfo))
    {
        // Inter-PAN frames are not supported by
        // the defragmenter. The specification is
        // incomplete when it comes to such frames.
        return NULL;
    }
    if (!whip6_lowpanFrameHeadersHasFragHeader(lowpanHdrs))
    {
        // The packet requires no defragmentation,
        // it is an error to pass it to this function.
        return NULL;
    }
    if (whip6_lowpanFrameHeadersGetFragHeaderSize(lowpanHdrs) < sizeof(ipv6_basic_header_t))
    {
        // The packet is smaller than the IPv6 header.
        // Obviously something is not right.
        return NULL;
    }
    // Get the PAN ID.
    whip6_ieee154DFrameGetDstPanId(
            frameInfo,
            (ieee154_pan_id_t MCS51_STORED_IN_RAM *)&state->scratchPad.tmpPanId
    );
    prevFragPacket = NULL;
    currFragPacket = state->currentPackets;
    while (currFragPacket != NULL)
    {
        if (currFragPacket->key.tag == whip6_lowpanFrameHeadersGetFragHeaderTag(lowpanHdrs))
        {
            // Our candidate. (For efficiency, we want to
            // force lazy evaluation, hence the nested if.
            if (whip6_ieee154AddrAnyCmp(&currFragPacket->key.srcLinkAddr, whip6_lowpanFrameHeadersGetMeshHeaderSrcAddrPtr(lowpanHdrs)) == 0 &&
                    whip6_ieee154AddrAnyCmp(&currFragPacket->key.dstLinkAddr, whip6_lowpanFrameHeadersGetMeshHeaderDstAddrPtr(lowpanHdrs)) == 0 &&
                    whip6_ieee154PanIdCmp(&currFragPacket->key.commonPanId, (ieee154_pan_id_t MCS51_STORED_IN_RAM *)&state->scratchPad.tmpPanId) == 0)
            {
                break;
            }
        }
        prevFragPacket = currFragPacket;
        currFragPacket = currFragPacket->next;
    }
    if (currFragPacket == NULL)
    {
PACKET_NOT_EXISTS:
        // There is no existing packet with
        // the given key, so let's try to
        // allocate a new one.
        currFragPacket = state->freePackets;
        if (currFragPacket == NULL)
        {
            // There are not free packets.
            return NULL;
        }
        currFragPacket->totalSize =
                whip6_lowpanFrameHeadersGetFragHeaderSize(lowpanHdrs);
        currFragPacket->packet =
                whip6_ipv6AllocatePacket(
                        currFragPacket->totalSize - sizeof(ipv6_basic_header_t)
                );
        if (currFragPacket->packet == NULL)
        {
            // We are unable to allocate a packet,
            // so we can return NULL as nothing
            // has changed in the state so far.
            return NULL;
        }
        currFragPacket->key.tag =
                whip6_lowpanFrameHeadersGetFragHeaderTag(lowpanHdrs);
        whip6_ieee154AddrAnyCpy(
                whip6_lowpanFrameHeadersGetMeshHeaderSrcAddrPtr(lowpanHdrs),
                &currFragPacket->key.srcLinkAddr
        );
        whip6_ieee154AddrAnyCpy(
                whip6_lowpanFrameHeadersGetMeshHeaderDstAddrPtr(lowpanHdrs),
                &currFragPacket->key.dstLinkAddr
        );
        whip6_ieee154PanIdCpy(
                (ieee154_pan_id_t MCS51_STORED_IN_RAM *)&state->scratchPad.tmpPanId,
                &currFragPacket->key.commonPanId
        );
        currFragPacket->firstFragSpec.offset = 0;
        currFragPacket->firstFragSpec.size = 0;
        currFragPacket->firstFragSpec.next = NULL;
        currFragPacket->defragStartTime = currTimeInMs;
        state->freePackets = currFragPacket->next;
    }
    else
    {
        // There is an existing packet, so
        // we have to remove it from the
        // current list to lock it.
        if (prevFragPacket == NULL)
        {
            state->currentPackets = currFragPacket->next;
        }
        else
        {
            prevFragPacket->next = currFragPacket->next;
        }
        if (currFragPacket->totalSize != whip6_lowpanFrameHeadersGetFragHeaderSize(lowpanHdrs))
        {
            whip6_lowpanDefragmenterDestroyDefragPacket(state, currFragPacket);
            goto PACKET_NOT_EXISTS;
        }
    }
    currFragPacket->next = state->lockedPackets;
    state->lockedPackets = currFragPacket;
    return currFragPacket;
}



/**
 * Prints all fragments associated with a given packet.
 * NOTICE: Comment this function when unused.
 * @param lockedDefragPacket The packet for which the
 *   specifications should be printed.
 */
/*WHIP6_MICROC_PRIVATE_DEF_PREFIX void __whip6_lowpanDefragmentePrintFragmentSpecs(
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM * currFragSpec;

    printf("Fragments:");
    currFragSpec = &lockedDefragPacket->firstFragSpec;
    do
    {
        printf(" [off=%u;len=%u]", (unsigned)currFragSpec->offset, (unsigned)currFragSpec->size);
        currFragSpec = currFragSpec->next;
    }
    while (currFragSpec != NULL);
    printf("\n\r");
}*/

#define whip6_lowpanDefragmentePrintFragmentSpecs(p)
// #define whip6_lowpanDefragmentePrintFragmentSpecs(p) __whip6_lowpanDefragmentePrintFragmentSpecs(p)



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterPassFrameWithIpv6PacketFragment(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *               payloadPtr;
    ieee154_frame_length_t                            payloadLen;
    ieee154_frame_length_t                            fragmentLen;
    lowpan_header_frag_dgram_offset_t                 newFragOffset;
    lowpan_defrag_frag_spec_t MCS51_STORED_IN_RAM *   prevFragSpec;

    // Unlock the packet.
    if (whip6_lowpanDefragmenterUnlockDefragPacket(state, lockedDefragPacket))
    {
        // NOTICE iwanicki 2013-03-03:
        // If the packet is not locked, then we have
        // a serious problem. Let's just drop the packet.
        // At worst, we will have a memory leak.
        goto FAILURE_ROLLBACK_0;
    }
    // Check its length and set the payload pointer.
    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo);
    payloadLen = whip6_ieee154DFrameGetPayloadLen(frameInfo);
    fragmentLen = lowpanHdrs->nextOffset;
    if (fragmentLen >= payloadLen)
    {
        goto FAILURE_ROLLBACK_1;
    }
    payloadPtr += fragmentLen;
    payloadLen -= fragmentLen;
    // Check which fragment we are dealing with.
    newFragOffset = whip6_lowpanFrameHeadersGetFragHeaderOffset(lowpanHdrs);
    if (newFragOffset == 0)
    {
        // This is the first fragment.
        // Check what the next header is.
        if (((*payloadPtr) & LOWPAN_DISPATCH_MASK_IPV6) == LOWPAN_DISPATCH_PATTERN_IPV6)
        {
            uint8_t identical;
            identical = 0;
            fragmentLen =
                    whip6_lowpanRawIpv6HeaderUnpack(
                            frameInfo,
                            lowpanHdrs,
                            lockedDefragPacket->packet,
                            lockedDefragPacket->firstFragSpec.size > 0 ?
                                    &identical : NULL
                    );
            if (fragmentLen == 0)
            {
                goto FAILURE_ROLLBACK_1;
            }
            // NOTICE iwanicki 2013-03-15:
            // We need not do any searching here, because
            // we always append to the first spec.
            if (whip6_lowpanDefragmenterMergeNewFragSpecIntoPacket(
                    state, lockedDefragPacket, NULL, 0, fragmentLen, identical))
            {
                goto FAILURE_ROLLBACK_1;
            }
            whip6_lowpanDefragmentePrintFragmentSpecs(lockedDefragPacket);
        }
        // NOTICE iwanicki 2013-03-03:
        // IPv6 header compression should be implemented here.
        else
        {
            goto FAILURE_ROLLBACK_1;
        }
    }
    else
    {
        uint8_t                  identical;
        ieee154_frame_length_t   tmpFragmentLen;
        // This is not the first fragment, so
        // we just need to copy bytes.
        if (payloadLen == 0 || ((payloadLen & 0x7) != 0 &&
                newFragOffset + payloadLen != whip6_lowpanFrameHeadersGetFragHeaderSize(lowpanHdrs)))
        {
            // The next offset would not
            // be divisible by 8.
            goto FAILURE_ROLLBACK_1;
        }
        // Check if we are still defragmenting the
        // IPv6 packet header.
        fragmentLen = 0;
        identical = 1;
        if (newFragOffset < sizeof(ipv6_basic_header_t))
        {
            tmpFragmentLen =
                    sizeof(ipv6_basic_header_t) -
                            (ieee154_frame_length_t)newFragOffset;
            if (tmpFragmentLen > payloadLen)
            {
                tmpFragmentLen = payloadLen;
            }
            if (whip6_shortMemCmp(
                    payloadPtr,
                    ((uint8_t MCS51_STORED_IN_RAM *)&lockedDefragPacket->packet->header) +
                            newFragOffset,
                    tmpFragmentLen) != 0)
            {
                identical = 0;
            }
            whip6_shortMemCpy(
                    payloadPtr,
                    ((uint8_t MCS51_STORED_IN_RAM *)&lockedDefragPacket->packet->header) +
                            newFragOffset,
                    tmpFragmentLen
            );
            payloadPtr += tmpFragmentLen;
            payloadLen -= tmpFragmentLen;
            fragmentLen = tmpFragmentLen;
        }
        if (payloadLen > 0)
        {
            if (whip6_iovShortCompare(
                    lockedDefragPacket->packet->firstPayloadIov,
                    newFragOffset + fragmentLen - sizeof(ipv6_basic_header_t),
                    payloadPtr,
                    payloadLen) != 0)
            {
                identical = 0;
            }
            tmpFragmentLen =
                    whip6_iovShortWrite(
                            lockedDefragPacket->packet->firstPayloadIov,
                            newFragOffset + fragmentLen - sizeof(ipv6_basic_header_t),
                            payloadPtr,
                            payloadLen
                    );
            if (tmpFragmentLen != payloadLen)
            {
                // Something went wrong with copying.
                goto FAILURE_ROLLBACK_1;
            }
            fragmentLen += tmpFragmentLen;
        }
        prevFragSpec =
                whip6_lowpanDefragmenterFindWhereNewFragSpecShouldBeInserted(
                        lockedDefragPacket,
                        newFragOffset
                );
        if (whip6_lowpanDefragmenterMergeNewFragSpecIntoPacket(
                state, lockedDefragPacket, prevFragSpec, newFragOffset, fragmentLen, identical))
        {
            goto FAILURE_ROLLBACK_1;
        }
        whip6_lowpanDefragmentePrintFragmentSpecs(lockedDefragPacket);
    }
    // Check if the packet is complete.
    if (lockedDefragPacket->firstFragSpec.offset == 0 &&
            lockedDefragPacket->firstFragSpec.size == whip6_lowpanFrameHeadersGetFragHeaderSize(lowpanHdrs))
    {
        // The packet is complete, so we can
        // return it first freeing the
        // defragmenter state.
        ipv6_packet_t MCS51_STORED_IN_RAM *   packetPtr;
        packetPtr = lockedDefragPacket->packet;
        lockedDefragPacket->packet = NULL;
        whip6_lowpanDefragmenterDestroyDefragPacket(state, lockedDefragPacket);
        return packetPtr;
    }
    else
    {
        // The packet is not yet complete, so
        // we have to add it back to our list.
        lockedDefragPacket->next = state->currentPackets;
        state->currentPackets = lockedDefragPacket;
        return NULL;
    }
FAILURE_ROLLBACK_1:
    whip6_lowpanDefragmenterDestroyDefragPacket(state, lockedDefragPacket);
FAILURE_ROLLBACK_0:
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanDefragmenterPassFrameWithEntireIpv6Packet(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        ieee154_dframe_info_t MCS51_STORED_IN_RAM const * frameInfo,
        lowpan_unpacked_frame_headers_t MCS51_STORED_IN_RAM const * lowpanHdrs
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_packet_t MCS51_STORED_IN_RAM *               packet = NULL;
    uint8_t MCS51_STORED_IN_RAM const *               payloadPtr;
    ieee154_frame_length_t                            payloadLen;
    ieee154_frame_length_t                            tmp;

    (void)state;
    if (whip6_ieee154DFrameIsInterPan(frameInfo))
    {
        // Inter-PAN frames are not supported by
        // the defragmenter. The specification is
        // incomplete when it comes to such frames.
        goto FAILURE_ROLLBACK_0;
    }
    if (whip6_lowpanFrameHeadersHasFragHeader(lowpanHdrs))
    {
        // The packet requires defragmentation,
        // it is an error to pass it to this function.
        goto FAILURE_ROLLBACK_0;
    }
    payloadPtr = whip6_ieee154DFrameUnsafeGetPayloadPtr(frameInfo);
    payloadLen = whip6_ieee154DFrameGetPayloadLen(frameInfo);
    tmp = lowpanHdrs->nextOffset;
    if (tmp >= payloadLen)
    {
        goto FAILURE_ROLLBACK_0;
    }
    payloadPtr += tmp;
    payloadLen -= tmp;
    tmp = (*payloadPtr);
    if ((tmp & LOWPAN_DISPATCH_MASK_IPV6) == LOWPAN_DISPATCH_PATTERN_IPV6)
    {
        ++payloadPtr;
        --payloadLen;
        if (payloadLen < sizeof(ipv6_basic_header_t))
        {
            // The packet is smaller than the IPv6 header.
            // Obviously something is not right.
            goto FAILURE_ROLLBACK_0;
        }
        packet =
                whip6_ipv6AllocatePacket(
                        payloadLen - sizeof(ipv6_basic_header_t)
                );
        if (packet == NULL)
        {
            // Packet allocation failed.
            goto FAILURE_ROLLBACK_0;
        }
        tmp =
                whip6_lowpanRawIpv6HeaderUnpack(
                        frameInfo,
                        lowpanHdrs,
                        packet,
                        NULL
                );
        if (tmp != payloadLen)
        {
            // Packet copying failed.
            goto FAILURE_ROLLBACK_1;
        }
        payloadLen -= sizeof(ipv6_basic_header_t);
    }
    // NOTICE iwanicki 2013-03-17:
    // IPv6 header compression should be implemented here.
    else
    {
        goto FAILURE_ROLLBACK_0;
    }
    if (whip6_ipv6BasicHeaderGetPayloadLength(&packet->header) != payloadLen)
    {
        // The packet has an incorrect length.
        goto FAILURE_ROLLBACK_1;
    }
    return packet;
FAILURE_ROLLBACK_1:
    whip6_ipv6FreePacket(packet);
FAILURE_ROLLBACK_0:
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanDefragmenterUnlockPacket(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * lockedDefragPacket
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (whip6_lowpanDefragmenterUnlockDefragPacket(state, lockedDefragPacket))
    {
        return WHIP6_ARGUMENT_ERROR;
    }
    lockedDefragPacket->next = state->currentPackets;
    state->currentPackets = lockedDefragPacket;
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanDefragmenterPeriodicTimeout(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state,
        defrag_time_in_ms_t currTimeInMs,
        defrag_time_in_ms_t reassemblyTimeoutInMs
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   currFragPacket;
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   prevFragPacket;

    if (state->lockedPackets != NULL)
    {
        return WHIP6_STATE_ERROR;
    }
    prevFragPacket = NULL;
    currFragPacket = state->currentPackets;
    while (currFragPacket != NULL)
    {
        defrag_time_in_ms_t   dt;
        dt = currTimeInMs - currFragPacket->defragStartTime;
        if (dt < reassemblyTimeoutInMs)
        {
            // The reassembly of the packet can be continued.
            prevFragPacket = currFragPacket;
            currFragPacket = currFragPacket->next;
        }
        else
        {
            // The reassembly of the packet must be terminated.
            lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * nextFragPacket;
            nextFragPacket = currFragPacket->next;
            if (prevFragPacket == NULL)
            {
                state->currentPackets = nextFragPacket;
            }
            else
            {
                prevFragPacket->next = nextFragPacket;
            }
            whip6_lowpanDefragmenterDestroyDefragPacket(state, currFragPacket);
            currFragPacket = nextFragPacket;
        }
    }
    return WHIP6_NO_ERROR;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX whip6_error_t whip6_lowpanDefragmenterTerminateAllReassemblies(
        lowpan_defrag_global_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM *   currFragPacket;

    if (state->lockedPackets != NULL)
    {
        return WHIP6_STATE_ERROR;
    }
    currFragPacket = state->currentPackets;
    while (currFragPacket != NULL)
    {
        lowpan_defrag_packet_state_t MCS51_STORED_IN_RAM * nextFragPacket;
        nextFragPacket = currFragPacket->next;
        whip6_lowpanDefragmenterDestroyDefragPacket(state, currFragPacket);
        currFragPacket = nextFragPacket;
    }
    state->currentPackets = NULL;
    return WHIP6_NO_ERROR;
}
