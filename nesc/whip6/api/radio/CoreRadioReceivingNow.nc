/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <PlatformFrame.h>

interface CoreRadioReceivingNow
{
  /**
   * Returns true if the radio got a Start of Frame Delimiter and is
   * currently receiving a frame. This may indicate that reception should
   * not timeout yet.
   */
  command bool receivingBytesNow();
}
