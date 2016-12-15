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

#include <base/ucIoVec.h>


/**
 * An internal writer interface for a discrete stream.
 *
 * @author Konrad Iwanicki
 */
interface InternalDiscreteStreamWriter
{
    /**
     * Starts writing a data unit represented by an IOV.
     * @param iov The IOV to be written.
     * @param size The number of bytes to write.
     * @param channel The channel to use.
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
    command error_t initiateWriting(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel
    );
    
    /**
     * Stops writing a data unit represented by an IOV.
     * @param iov The IOV writing which should be stopped.
     * @param channel The channel assigned to the IOV.
     * @return SUCCESS if writing the IOV has finished
     *   successfully; EINVAL if the IOV is not being written.
     *   In any case, the <tt>finishedWriting</tt> will still be
     *   signaled.
     */
    command error_t cancelWriting(
            whip6_iov_blist_t * iov,
            uint8_t channel
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
    event void doneWriting(
            whip6_iov_blist_t * iov,
            uint16_t size,
            uint8_t channel,
            error_t status
    );
}

