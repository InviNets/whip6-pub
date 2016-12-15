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

/**
 * @author Szymon Acedanski
 *
 * The platform must wire some pins in the HalI2CPinsPub component.
 */

#include <inc/hw_memmap.h>

configuration HalBlockingI2CPub {
    provides interface OnOffSwitch @atleastonce();
    provides interface BlockingI2CPacket<TI2CBasicAddr>;
}

implementation {
    components new HalBlockingI2CPrv(I2C0_BASE) as Prv;
    BlockingI2CPacket = Prv.BlockingI2CPacket;

    components new HalConfigureI2CMasterPrv(I2C0_BASE) as Conf;
    components HalI2CPinsPub as Pins;
    Conf.SDAPin -> Pins.PSDA;
    Conf.SCLPin -> Pins.PSCL;
    OnOffSwitch = Conf.OnOffSwitch;

    components CC26xxPowerDomainsPub as PowerDomains;
    Conf.PowerDomain -> PowerDomains.SerialDomain;

    components HalCC26xxSleepPub;
    Conf.ReInitRegisters <- HalCC26xxSleepPub.AtomicAfterDeepSleepInit;
}
