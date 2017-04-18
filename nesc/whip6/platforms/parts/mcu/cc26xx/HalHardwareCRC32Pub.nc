/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

#include <driverlib/rom.h>

module HalHardwareCRC32Pub {
    provides interface CRC32;
}
implementation {
    command uint32_t CRC32.getChecksum(uint8_t_xdata *data, size_t len) {
        return HapiCrc32(data, len, 0);
    }
}
