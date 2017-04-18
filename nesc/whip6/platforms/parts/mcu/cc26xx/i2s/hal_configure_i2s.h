/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
