/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @file
 * @author Przemyslaw Horban <extremegf@gmail.com>
 *
 * Stores configuration constants for UART
 */

#ifndef _HAL_CONFIGURE_UART_H
#define _HAL_CONFIGURE_UART_H

/**
 * Should be used as a first argument to HalConfigureUARTPrv or
 * HalBufferedUARTxPrv.
 */
#define BAUD_RATE_2400   2400
#define BAUD_RATE_4800   4800
#define BAUD_RATE_57600  57600
#define BAUD_RATE_115200 115200
#define BAUD_RATE_230400 230400
#define BAUD_RATE_460800 460800

#endif  // _HAL_CONFIGURE_UART_H
