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
 * Interface providing access to RSSI information in platform_frame_t.
 */
interface RawFrameRSSI
{
  /**
   * Returns the frame RSSI in dBm.
   */
  command int8_t getRSSI(platform_frame_t * framePtr);
}
