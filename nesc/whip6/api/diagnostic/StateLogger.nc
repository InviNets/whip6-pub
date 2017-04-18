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
 * @author Przemyslaw Horban
 *
 * Used to log state transitions in finite state automatons.
 */
interface StateLogger
{
    /**
     * Writes 1 byte to the bytelog.
     */
    command void log8(uint8_t data);

    /**
     * Writes 2 bytes to the bytelog.
     */
    command void log16(uint16_t data);

    /**
     * Writes 4 bytes to the bytelog.
     */
    command void log32(uint32_t data);

    /**
     * Writes logged data to storage.
     * Whatever that may be.
     */
    command void writeEntry();
}
