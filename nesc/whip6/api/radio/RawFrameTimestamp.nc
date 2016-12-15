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


#include <PlatformFrame.h>
#include <TimerTypes.h>

/**
 * Interface providing access to LQI information in platform_frame_t.
 */
interface RawFrameTimestamp<precision_tag>
{
  /**
   * Returns the frame timestamp, measured accoring to the given
   * precision_tag. It is undefined, when the time is measured from
   * (i.e. what does zero mean). The timestamp naturally overflows.
   */
  command uint32_t getTimestamp(platform_frame_t * framePtr);
}
