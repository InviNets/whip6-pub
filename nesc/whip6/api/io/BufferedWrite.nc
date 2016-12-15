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

interface BufferedWrite {
    /**
     * Begins writing a buffer.
     *
     * @return SUCCESS if buffer will eventually be sent.
     */
    command error_t startWrite(uint8_t_xdata *buffer, uint16_t size);

    /**
     * Reports that a buffer was written.
     */
    event void writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size);
}
