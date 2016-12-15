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

interface PacketRead {
    /**
     * Registers a buffer where the next packet is to be placed. If a packet
     * bigger than the buffer is received, it's dropped.
     *
     * @return EBUSY if a buffer is already registered, SUCCESS otherwise.
     */
    command error_t startRead(uint8_t_xdata *buffer, uint16_t capacity);

    /**
     * Reports that a packet was received.
     */
    event void readDone(uint8_t_xdata *buffer, uint16_t packet_len);
}
