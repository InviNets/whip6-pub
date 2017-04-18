/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "RawRSSI.h"

/**
 * Interface providing access to RSSI information during reception.
 */
interface RawRSSI
{
  /**
   * Returns the current energy level RSSI in dBm. If not available,
   * RAW_RSSI_INVALID.
   *
   * Valid values are returned only in radio states, which provide it.
   * It is the responsibility of the user to configure the radio
   * for RX/energy detect before obtaining measurements.
   */
  command int8_t getRSSI();
}
