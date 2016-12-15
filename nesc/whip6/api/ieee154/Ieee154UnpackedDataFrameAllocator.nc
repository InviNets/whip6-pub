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

#include "Ieee154.h"


/**
 * An allocator of unpacked IEEE 802.15.4 data frames.
 *
 * @author Konrad Iwanicki
 */
interface Ieee154UnpackedDataFrameAllocator
{
    /**
     * Allocates a buffer for a frame.
     * @return A pointer to the allocated buffer
     *   or NULL if there is no memory left.
     */
    command whip6_ieee154_dframe_info_t * allocFrame();

    /**
     * Frees a buffer for a frame.
     * @param framePtr A pointer to the freed buffer.
     */
    command void freeFrame(whip6_ieee154_dframe_info_t * framePtr);
}

