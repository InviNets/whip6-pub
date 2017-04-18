/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>



/**
 * A reader of a discrete stream, that is, a stream
 * consisting of data units (e.g., packets, frames,
 * data records) that have to be read indivisibly or
 * not at all.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * @author Konrad Iwanicki
 */
interface DiscreteStreamReader
{

    /**
     * Starts reading a data unit of a given maximal size.
     * Data units greater than the maximal size will be
     * silently ignored.
     * @param maxSize The maximal size.
     * @return SUCCESS if the reading was started in which case
     *   the <tt>provideIOVForReading</tt> event is guaranteed
     *   to be invoked; or an error code otherwise, in which
     *   case no <tt>provideIOVForReading</tt> event will be
     *   invoked. Possible errors:
     *     EBUSY if reading has already started,
     *     EINVAL if <tt>maxSize</tt> is zero.
     */
    command error_t startReadingDataUnit(
            size_t maxSize
    );

    /**
     * Signaled when a data unit whose size does not
     * exceed the previously provided maximal size
     * (with <tt>startReadingDataUnit</tt>) is ready
     * to be read, and hence, requires an I/O vector
     * for storage.
     * @param size The actual size of the data unit.
     * @return A pointer to an I/O vector that will
     *   hold the data unit when it has been read.
     *   If the pointer is NULL, reading the unit
     *   is aborted and a next unit with the previously
     *   given maximal size is automatically awaited
     *   (there is no need to invoke
     *   <tt>startReadingDataUnit</tt> again).
     *   If the returned I/O vector is too short, the
     *   reading will complete (the
     *   <tt>finishedReadingDataUnit</tt> event will
     *   be signaled), but with an appropriate error code.
     */
    event whip6_iov_blist_t * provideIOVForDataUnit(
            size_t size
    );

    /**
     * Signaled when reading a data unit for which an
     * I/O vector was previously provided (with the
     * <tt>provideIOVForDataUnit</tt> event) has completed.
     * Note that the event does not mean that the data
     * unit has actually been read successfully.
     * To start another read, the <tt>startReadingDataUnit</tt>
     * command must be called explicitly (e.g., from the
     * event handler).
     * @param iov The I/O vector provided previously with
     *   <tt>provideIOVForDataUnit</tt> or NULL if no
     *   <tt>provideIOVForDataUnit</tt> was signaled. In the
     *   first case, if the reading is successful, the I/O
     *   vector contains the data unit; otherwise, the status
     *   is equal to EOFF.
     * @param size The size of the data unit (the same as
     *   the one passed to the previous <tt>provideIOVForDataUnit</tt>).
     * @param status The status of the read.
     *   SUCCESS if the read was successful, in which case
     *   the I/O vector contains a data unit of <tt>size</tt>
     *   bytes; ESIZE if the I/O vector is too short to hold
     *   <tt>size</tt> bytes or another error code otherwise,
     *   in which case the contents of the I/O vector are
     *   undefined.
     */
    event void finishedReadingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    );
}
