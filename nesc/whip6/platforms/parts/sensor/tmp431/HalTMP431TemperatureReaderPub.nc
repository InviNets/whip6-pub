/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 *
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Provides reads from a TI TMP431 thermometers.
 *
 * The address of the TMP431A/32A/31C is 0x4C (1001100b). The address of the
 * TMP431B/32B/31D is 0x4D (1001101b).
 */

#include "I2CDefs.h"

generic configuration HalTMP431TemperatureReaderPub() {
    provides interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;

    uses interface OnOffSwitch;
    uses interface I2CPacket<TI2CBasicAddr>;
    uses interface Resource;
}

implementation {
    components new HalTMP431TemperatureReaderPrv() as Reader;

    components new PlatformTimerMilliPub() as EnableTimer;
    Reader.EnableDelay -> EnableTimer;

    components new PlatformTimerMilliPub() as SettlingTimer;
    Reader.SettlingDelay -> SettlingTimer;

    ReadTemp = Reader;
    I2CPacket = Reader;
    OnOffSwitch = Reader;
    Resource = Reader;
}
