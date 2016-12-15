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
 */

#include "hal_configure_spi.h"

module SdCardSpiConfigPrv {
    provides interface ResourceConfigure;

    uses interface AsyncConfigure<spi_mode_t> as Mode;
    uses interface AsyncConfigure<spi_speed_t> as Speed;
    uses interface AsyncConfigure<spi_order_t> as BitOrder;
}

implementation {
    async command void ResourceConfigure.configure() {
        call Mode.configure(SPI_MODE_0);
        call Speed.configure(SPI_SPEED_250KHZ);
        call BitOrder.configure(SPI_ORDER_MSB_FIRST);
    }

    async command void ResourceConfigure.unconfigure() {}
}
