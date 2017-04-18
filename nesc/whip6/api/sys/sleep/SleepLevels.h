/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef SLEEP_LEVELS_H
#define SLEEP_LEVELS_H

enum sleep_level {
    // For efficiency, each level is represented as a number
    // of LSBs set, so that they can be combined using & operator.
    SLEEP_LEVEL_NONE = 0x01,
    SLEEP_LEVEL_IDLE = 0x03,
    SLEEP_LEVEL_DEEP = 0x07
};

typedef enum sleep_level sleep_level_t @combine("sleep_level_combine");

inline sleep_level_t sleep_level_combine(sleep_level_t a, sleep_level_t b) {
    return a & b;
}

#endif
