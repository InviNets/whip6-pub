/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
#ifndef RFCORE_FRAME_H
#define RFCORE_FRAME_H

#include <RawFrame.h>

typedef struct {
    uint16_t fcs;
    int8_t rssi;
    struct {
        unsigned corr : 6;
        unsigned ignore : 1;
        unsigned crcerr : 1;
    } __attribute__((packed));
    uint32_t timestamp;
} __attribute__((packed)) rfcore_frame_extras_t;

typedef struct _rfcore_frame_s {
    _raw_frame_t raw_frame;
    rfcore_frame_extras_t extras;
} __attribute__((packed)) rfcore_frame_t;

#endif
