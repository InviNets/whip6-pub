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
 * Interface providing access to transparent type platform_frame_t.
 */
interface RawFrame
{
  command uint8_t getLength(platform_frame_t * framePtr);
  command void setLength(platform_frame_t * framePtr, uint8_t length);
  command uint8_t maxLength();

  /*
   * Returns a pointer to the data part of the frame's buffer.
   */
  command uint8_t_xdata * getData(platform_frame_t * framePtr);

  /*
   * Returns a pointer to the frame's buffer. You may assume that its layout
   * is:
   *  - uint8_t length
   *  - uint8_t data[MAX_RAW_FRAME_LENGTH]
   */
  command uint8_t_xdata * getRawPointer(platform_frame_t * framePtr);

  /*
   * Returns the maximum length of the raw data (including the length field).
   * See also getRawPointer above.
   */
  command uint8_t maxRawLength();

  command uint8_t_xdata * nextHeader(platform_frame_t * framePtr);
}
