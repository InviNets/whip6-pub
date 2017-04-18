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

interface BufferedRead {
    /**
     * Activates or deactivates the data source. Incoming bytes are either
     * fed to the buffer or reported as lost.
     */
    command void setActive(bool active);

    /**
     * Registers a buffer, to be filled with bytes. There can be at most
     * one buffer registered at a time.
     *
     * @return EBUSY if a buffer is already registered, SUCCESS otherwise.
     */
    command error_t startRead(uint8_t_xdata *buffer, uint16_t capacity);

    /**
     * Reports that a buffer was filled with bytes.
     *
     * To avoid losing data during a short time before the buffer is filled and
     * a next call to startRead is performed, BufferedRead providers should
     * implement a small internal buffer for storing data when no buffer is
     * registered.
     */
    event void readDone(uint8_t_xdata *buffer, uint16_t capacity);

    /**
     * Discards data which partially fills the currently active buffer (or any
     * internal buffers, if possible). No data which is received before the call
     * to flush should be read.
     *
     * If a buffer was registered, it is unregistered, without
     * readDone being signaled.
     */
    command void flush();

    /**
     * Reports that bytes were lost, due to lack of available buffers.
     */
    event void bytesLost(uint16_t lostCount);
}
