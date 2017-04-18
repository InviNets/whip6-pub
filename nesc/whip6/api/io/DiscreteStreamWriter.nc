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
 * A writer of a discrete stream, that is, a stream
 * consisting of data units (e.g., packets, frames,
 * data records) that have to be written indivisibly or
 * not at all.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * @author Konrad Iwanicki
 */
interface DiscreteStreamWriter
{
    /**
     * Starts writing a data unit represented by an IOV.
     * @param iov The IOV to be written.
     * @param size The number of bytes to write.
     * @return SUCCESS if the IOV has been accepted for writing,
     *   in which case the <tt>finishedWriting</tt> event will
     *   eventually be signaled; an error code otherwise, in
     *   which case no <tt>finishedWriting</tt> event will be
     *   signaled. Possible errors:
     *   EINVAL if the IOV is invalid,
     *   ESIZE if there are no bytes or too many bytes to be
     *     written,
     *   EBUSY if another write is already in progress.
     */
    command error_t startWritingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size
    );

    /**
     * Signals the end of a write operation on an data
     * unit represented by an IOV.
     * @param iov The IOV on which the operation has
     *   completed.
     * @param size The number of written bytes.
     * @param status The final status of the write.
     *   SUCCESS if the data unit has been written
     *   successfully or an error code otherwise.
     */
    event void finishedWritingDataUnit(
            whip6_iov_blist_t * iov,
            size_t size,
            error_t status
    );
}
