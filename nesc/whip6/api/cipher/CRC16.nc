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
 * Calculate standard CRC16 checksum.
 */
interface CRC16 {
    /**
     * Return the checksum.
     */
    command uint16_t getChecksum(uint8_t_xdata *data, uint8_t len);
}
