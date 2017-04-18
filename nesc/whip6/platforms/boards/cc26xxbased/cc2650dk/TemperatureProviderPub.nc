/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "DimensionTypes.h"

generic configuration TemperatureProviderPub() {
  provides interface DimensionalRead<TDeciCelsius, int16_t>;
}
implementation {
  components new HalMCUTemperaturePub();
  DimensionalRead = HalMCUTemperaturePub;
}
