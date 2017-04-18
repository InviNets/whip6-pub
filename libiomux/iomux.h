/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#ifndef IOMUX_H
#define IOMUX_H

#include <stddef.h>
#include <stdint.h>

int iomux_write_packet(int fd, uint8_t channel, const char* buf,
        uint16_t len);
int iomux_read_packet(int fd, void* buf, size_t* len, uint8_t* channel);

#endif
