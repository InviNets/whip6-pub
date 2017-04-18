/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef RAW_FRAME_H
#define RAW_FRAME_H

#ifndef PLATFORM_MAX_PAYLOAD
#define PLATFORM_MAX_PAYLOAD 127
#endif

typedef struct _raw_frame_s {
  uint8_t length;
  uint8_t data[PLATFORM_MAX_PAYLOAD];
} _raw_frame_t;
typedef _raw_frame_t _raw_frame_t_xdata;
typedef _raw_frame_t_xdata raw_frame_t;

#endif
