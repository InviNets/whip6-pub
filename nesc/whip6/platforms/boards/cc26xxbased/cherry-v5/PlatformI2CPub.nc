/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include "I2CDefs.h"

generic configuration PlatformI2CPub(int usPerBit) {
    provides interface ArbiterInfo;
    provides interface I2CPacket<TI2CBasicAddr>;
    provides interface Resource;
    provides interface ResourceRequested;

    uses interface ResourceConfigure;
}

implementation {
    components new PlatformI2CPrv(usPerBit) as I2C;
    I2CPacket = I2C;
    Resource = I2C;
    ResourceRequested = I2C;
    ArbiterInfo = I2C;
    ResourceConfigure = I2C;
}
