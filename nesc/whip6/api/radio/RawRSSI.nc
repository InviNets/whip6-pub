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
