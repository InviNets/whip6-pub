/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */



/**
 * @file
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Constants used for SPI configuration.
 */

#ifndef HAL_CONFIGURE_SPI_H
#define HAL_CONFIGURE_SPI_H

typedef enum {
    SPI_MODE_0,
    SPI_MODE_1,
    SPI_MODE_2,
    SPI_MODE_3,
} spi_mode_t;

typedef enum {
    SPI_SPEED_24MHZ,
    SPI_SPEED_16MHZ,
    SPI_SPEED_8MHZ,
    SPI_SPEED_4MHZ,
    SPI_SPEED_2MHZ,
    SPI_SPEED_1MHZ,
    SPI_SPEED_500KHZ,
    SPI_SPEED_250KHZ,
    /* add more here and in HalConfigreSPIMasterPrv.nc if needed */
    /* the maximum frequency for master operation is PERDMACLK / 2,
     * i.e. 24MHz. */
} spi_speed_t;

typedef enum {
    SPI_ORDER_MSB_FIRST,
    SPI_ORDER_LSB_FIRST,
} spi_order_t;

#endif
