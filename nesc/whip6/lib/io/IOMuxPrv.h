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

#ifndef IOMUX_H
#define IOMUX_H

// The magic must consist of distinct characters.
#define IOMUX_MAGIC 0xfeebbeef

struct iomux_header {
    uint8_t channel;
    uint16_t size;
} __attribute__((packed));


// TODO: we should have htons somewhere
// FIXME: endianness test

static inline uint16_t iomux_htons(uint16_t val) {
    return (val << 8) | (val >> 8);
}

static inline uint16_t iomux_ntohs(uint16_t val) {
    return iomux_htons(val);
}

#endif
