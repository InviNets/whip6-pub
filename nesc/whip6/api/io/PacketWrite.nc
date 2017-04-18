/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

interface PacketWrite {
    /**
     * Begins sending a packet.
     *
     * @return SUCCESS if packet will eventually be sent.
     */
    command error_t startWrite(uint8_t_xdata *buffer, uint16_t size);

    /**
     * Reports that a packet has been sent.
     */
    event void writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size);
}
