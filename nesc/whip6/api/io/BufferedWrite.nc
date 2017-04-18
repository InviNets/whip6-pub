/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
