/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>



/**
 * An internal reader interface for a discrete
 * stream.
 *
 * @author Konrad Iwanicki
 */
interface InternalDiscreteStreamReader
{

    /**
     * Invoked to start reading data from the stream.
     * @return SUCCESS if reading from the stream has
     *     started;
     *   EALREADY if reading is already active;
     *     another error code meaning that reading could
     *     not be started;
     *   EBUSY if the reading was stopped while
     *     a data unit was being read and the event
     *     signaling the end of reading has not
     *     been signaled yet.
     */
    command error_t startReading();
    
    /**
     * Invoked to stop reading data from the stream.
     * If some data unit is being read from
     * the stream, the reading will complete anyway
     * but with the ECANCEL code.
     * @return SUCCESS if reading from the stream has
     *     stopped;
     *   EALREADY if no reading is already active.
     */
    command error_t stopReading();

    /**
     * Signaled when a data unit has started being read,
     * and hence, requires an I/O vector for storage.
     * @param size The expected size of the data unit.
     *   It is always positive.
     * @param channel The channel of the data unit.
     * @return A pointer to an I/O vector that will
     *   hold the data unit when it has been read.
     *   If the pointer is NULL, reading the unit
     *   is aborted.
     *   If the returned I/O vector is too short, the
     *   reading will complete (the
     *   <tt>doneReading</tt> event will
     *   be signaled), but with an appropriate error
     *   code.
     */
    event whip6_iov_blist_t * readyToRead(
            uint16_t size,
            uint8_t channel
    );


    /**
     * Checks if something is being read.
     * @return TRUE if something is being read, or false
     *   otherwise.
     */
    command bool isReading();

    /**
     * Signaled when reading a data unit for which an
     * I/O vector was previously provided (with the
     * <tt>startedReadingDataUnit</tt> event) has completed.
     * Note that the event does not mean that the data
     * unit has actually been read successfully.
     * @param iov The I/O vector provided previously with
     *   <tt>readyToRead</tt>. If the reading is
     *   successful, it contains the data unit.
     * @param size The size of the data unit (the same as
     *   the one passed to the previous <tt>readyToRead</tt>).
     * @param status The status of the read.
     *   SUCCESS if the read was successful, in which case
     *   the I/O vector contains a data unit of <tt>size</tt>
     *   bytes; ESIZE if the I/O vector is too short to hold
     *   <tt>size</tt> bytes or another error code otherwise,
     *   in which case the contents of the I/O vector are
     *   undefined.
     */
    event void doneReading(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel,
            error_t status
    );
}
