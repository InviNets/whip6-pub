/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */

#include <inc/hw_memmap.h>
#include <driverlib/udma.h>
#include "hal_configure_spi.h"
#include "hal_spi_resource.h"

configuration HalSPI0Prv {
    provides interface AsyncConfigure<spi_mode_t> as Mode;
    provides interface AsyncConfigure<spi_speed_t> as Speed;
    provides interface AsyncConfigure<spi_order_t> as BitOrder;
    provides interface SpiByte[uint8_t client];
    provides interface SpiPacket[uint8_t client];
    provides interface Resource[uint8_t client];
    provides interface ResourceRequested[uint8_t client];
    provides interface ArbiterInfo;

    uses interface ResourceConfigure[uint8_t client];
}

implementation {
    components HplSSIInterruptsPub;
    components HalDMAPub;
    components new HalGenericSpiPrv(SSI0_BASE) as GenericSpi;
    GenericSpi.Interrupt -> HplSSIInterruptsPub.SSI0Interrupt;
    GenericSpi.TXChannel -> HalDMAPub.DMAChannel[UDMA_CHAN_SSI0_TX];
    GenericSpi.RXChannel -> HalDMAPub.DMAChannel[UDMA_CHAN_SSI0_RX];

    components HalSPI0PinsPub as Pins;
    components new HalConfigureSPIMasterPrv(SSI0_BASE) as Configure;
    Configure.MIPin -> Pins.PMISO;
    Configure.MOPin -> Pins.PMOSI;
    Configure.CPin -> Pins.PCLK;
    Configure.DMAPower -> HalDMAPub.ShareableOnOff;

    components HalCC26xxSleepPub;
    Configure.ReInitRegisters <- HalCC26xxSleepPub.AtomicAfterDeepSleepInit;

    components CC26xxPowerDomainsPub as PowerDomains;
    Configure.PowerDomain -> PowerDomains.SerialDomain;

    components new FcfsArbiterPub(RESOURCE_SPI0) as Arbiter;
    components new PowerManagerPub();
    PowerManagerPub.OnOffSwitch -> Configure;
    PowerManagerPub.ResourceDefaultOwner -> Arbiter;

    Mode = Configure.Mode;
    Speed = Configure.Speed;
    BitOrder = Configure.BitOrder;
    SpiByte = GenericSpi;
    SpiPacket = GenericSpi;
    Resource = Arbiter;
    ResourceRequested = Arbiter;
    ArbiterInfo = Arbiter;
    ResourceConfigure = Arbiter;
}
