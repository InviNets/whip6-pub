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

#ifndef HAL_CONFIGURE_I2C_H
#define HAL_CONFIGURE_I2C_H

typedef enum {
    I2S_WORD_16BIT,
    I2S_WORD_24BIT,
} i2s_word_size_t;

typedef enum {
    I2S_CLOCK_POL_NORMAL,
    I2S_CLOCK_POL_INVERTED
} i2s_clock_pol_t;

#endif
