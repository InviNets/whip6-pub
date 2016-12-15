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

/**
 * Calculate standard CRC32 checksum.
 */
interface CRC32 {
    /**
     * Return the checksum.
     */
    command uint32_t getChecksum(uint8_t_xdata *data, size_t len);
}
