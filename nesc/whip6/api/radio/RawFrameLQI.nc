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

/**
 * Interface providing access to LQI information in platform_frame_t.
 */
interface RawFrameLQI
{
  /**
   * Returns the frame LQI, per IEEE 802.15.4 standard. 0 means the
   * lowest-quality frame detectable by the radio, whereas 255 is a
   * maximum-quality frame.
   */
  command uint8_t getLQI(platform_frame_t * framePtr);
}
