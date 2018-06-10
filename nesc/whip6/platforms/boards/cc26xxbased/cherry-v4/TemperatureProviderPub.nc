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
#include <CC26xxPinConfig.h>


generic configuration TemperatureProviderPub() {
    provides interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
}

implementation {
    components new HalTMP431TemperatureReaderPub() as Reader;
    components new PlatformI2CPub(50);
    components new TemperatureReaderOnOffSwitch();

  	components BoardStartupPub;
  	BoardStartupPub.InitSequence[3] -> TemperatureReaderOnOffSwitch.Init;

	components CC26xxPinsPub as Pins;
	components new HalIOPinPub(OUTPUT_LOW) as IOPin;
	IOPin.CC26xxPin -> Pins.DIO6;
	TemperatureReaderOnOffSwitch.IOPin -> IOPin;

    Reader.I2CPacket -> PlatformI2CPub;
    Reader.OnOffSwitch -> TemperatureReaderOnOffSwitch;
    Reader.Resource -> PlatformI2CPub;

    ReadTemp = Reader;
}
