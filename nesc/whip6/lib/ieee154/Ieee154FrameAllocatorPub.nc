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
#include "GlobalError.h"


/**
 * A platform-independent allocator for
 * IEEE 802.15.4 frames.
 *
 * @author Konrad Iwanicki
 */
module Ieee154FrameAllocatorPub
{
    provides
    {
        interface Init @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as PlatformIdependentAllocator;
    }
    uses
    {
        interface Init as PlatformSpecificInit @atmostonce();
        interface Ieee154UnpackedDataFrameAllocator as PlatformSpecificAllocator @atmostonce();
    }
}
implementation
{
    command inline error_t Init.init()
    {
        return call PlatformSpecificInit.init();
    }

    command inline whip6_ieee154_dframe_info_t * PlatformIdependentAllocator.allocFrame()
    {
        return call PlatformSpecificAllocator.allocFrame();
    }

    command inline void PlatformIdependentAllocator.freeFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        call PlatformSpecificAllocator.freeFrame(framePtr);
    }

    default command inline error_t PlatformSpecificInit.init()
    {
        return SUCCESS;
    }

    default command inline whip6_ieee154_dframe_info_t * PlatformSpecificAllocator.allocFrame()
    {
        return NULL;
    }

    default command inline void PlatformSpecificAllocator.freeFrame(
            whip6_ieee154_dframe_info_t * framePtr
    )
    {
        // Do nothing.
    }

}

