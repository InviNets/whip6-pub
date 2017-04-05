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

generic configuration PlatformI2CPrv(int usPerBit) {
    provides interface ArbiterInfo;
    provides interface I2CPacket<TI2CBasicAddr>;
    provides interface Resource;
    provides interface ResourceRequested;

    uses interface ResourceConfigure;
}

implementation {
    enum {
        CLIENT_ID = unique(RESOURCE_SOFTWARE_I2C),
    };

    components new SimpleFcfsArbiterPub(RESOURCE_SOFTWARE_I2C) as Arbiter;
    components new SoftwareI2CPacketC(usPerBit) as SoftI2C;

    components BusyWaitProviderPub;
    SoftI2C.BusyWait -> BusyWaitProviderPub;

    components CC26xxPinsPub as Pins;

    components new HalIOPinPub(INPUT_FLOATING) as PinSDA;
    PinSDA.CC26xxPin -> Pins.DIO1;
    SoftI2C.SDA -> PinSDA;

    components new HalIOPinPub(INPUT_FLOATING) as PinSCL;
    PinSCL.CC26xxPin -> Pins.DIO0;
    SoftI2C.SCL -> PinSCL;

    I2CPacket = SoftI2C;
    Resource = Arbiter.Resource[CLIENT_ID];
    ResourceRequested = Arbiter.ResourceRequested[CLIENT_ID];
    ArbiterInfo = Arbiter.ArbiterInfo;
    ResourceConfigure = Arbiter.ResourceConfigure[CLIENT_ID];
}
