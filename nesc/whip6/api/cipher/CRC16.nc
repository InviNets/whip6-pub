/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
