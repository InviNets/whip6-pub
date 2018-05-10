/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include "DimensionTypes.h"

generic configuration TemperatureProviderPub() {
    provides interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
}

implementation {
    components new HalTMP431TemperatureReaderPub() as Reader;
    components new PlatformI2CPub(50);
    components new DummyOnOffSwitchPub();

    Reader.I2CPacket -> PlatformI2CPub;
    Reader.OnOffSwitch -> DummyOnOffSwitchPub;
    Reader.Resource -> PlatformI2CPub;

    ReadTemp = Reader;
}
