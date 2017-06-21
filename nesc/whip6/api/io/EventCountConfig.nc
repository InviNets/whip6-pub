/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

typedef enum {
    EVENT_COUNT_MODE_RISING_EDGE,
    EVENT_COUNT_MODE_FALLING_EDGE,
    EVENT_COUNT_MODE_BOTH,
} event_count_mode_t;

interface EventCountConfig {
    command event_count_mode_t getMode();
}
