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
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 *
 * SPI using the SSI0 module of CC2538.
 *
 * The platform must wire some pins in the HalSPI0PinsPub component.
 */

#include "hal_configure_spi.h"
#include "hal_spi_resource.h"

generic configuration HalSPI0Pub() {
    provides interface AsyncConfigure<spi_mode_t> as Mode;
    provides interface AsyncConfigure<spi_speed_t> as Speed;
    provides interface AsyncConfigure<spi_order_t> as BitOrder;
    provides interface SpiByte;
    provides interface SpiPacket;
    provides interface Resource;
    provides interface ResourceRequested;
    provides interface ArbiterInfo;

    uses interface ResourceConfigure;
}

implementation {
    enum {
        CLIENT_ID = unique(RESOURCE_SPI0),
    };

    components HalSPI0Prv as Spi;

    Mode = Spi.Mode;
    Speed = Spi.Speed;
    BitOrder = Spi.BitOrder;
    SpiByte = Spi.SpiByte[CLIENT_ID];
    SpiPacket = Spi.SpiPacket[CLIENT_ID];
    Resource = Spi.Resource[CLIENT_ID];
    ResourceRequested = Spi.ResourceRequested[CLIENT_ID];
    ArbiterInfo = Spi.ArbiterInfo;
    ResourceConfigure = Spi.ResourceConfigure[CLIENT_ID];
}
