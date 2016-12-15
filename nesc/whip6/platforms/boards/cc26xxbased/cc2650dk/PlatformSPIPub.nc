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
 */

#include "hal_configure_spi.h"

generic configuration PlatformSPIPub() {
    provides interface SpiByte;
    provides interface SpiPacket;
    provides interface AsyncConfigure<spi_mode_t> as Mode;
    provides interface AsyncConfigure<spi_speed_t> as Speed;
    provides interface AsyncConfigure<spi_order_t> as BitOrder;
    provides interface Resource;
    provides interface ResourceRequested;
    provides interface ArbiterInfo;

    uses interface ResourceConfigure;
}

implementation {
    components new HalSPI0Pub() as Spi;

    SpiByte = Spi.SpiByte;
    SpiPacket = Spi.SpiPacket;
    Mode = Spi.Mode;
    Speed = Spi.Speed;
    BitOrder = Spi.BitOrder;
    Resource = Spi.Resource;
    ResourceRequested = Spi.ResourceRequested;
    ArbiterInfo = Spi.ArbiterInfo;
    ResourceConfigure = Spi.ResourceConfigure;
}
