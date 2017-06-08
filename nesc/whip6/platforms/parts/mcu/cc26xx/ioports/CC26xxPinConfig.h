/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#ifndef CC26XX_PIN_CONFIG_H
#define CC26XX_PIN_CONFIG_H

typedef enum {
    INPUT_FLOATING,
    INPUT_PULL_UP,
    INPUT_PULL_DOWN,
    OUTPUT_HIGH,
    OUTPUT_LOW
} cc26xx_pin_config_t;

#endif
