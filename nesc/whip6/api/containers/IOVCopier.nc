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
 * A copier for I/O vectors.
 *
 * @author Konrad Iwanicki
 */
interface IOVCopier
{
    /**
     * Starts copying a given number of bytes
     * from a source I/O vector to a destination
     * I/O vector. After the copying the iterators
     * will be moved forward by the number of
     * copied bytes. The implementer of the command
     * takes over the ownership of the iterators.
     * @param srcIovIter A pointer to an iterator
     *   pointing at the first byte in the source
     *   I/O vector to be read.
     * @param dstIovIter A pointer to an iterator
     *   pointing at the first byte in the destination
     *   I/O vector to be written.
     * @param numBytes The number of bytes to copy.
     * @return SUCCESS if copying has been started
     *   successfully, in which case the
     *   <tt>finishCopying</tt> event is guaranteed
     *   to be signaled, or EBUSY if another copying
     *   is in progress, in which no <tt>finishCopying</tt>
     *   event will be signaled.
     */
    command error_t startCopying(
            whip6_iov_blist_iter_t * srcIovIter,
            whip6_iov_blist_iter_t * dstIovIter,
            size_t numBytes
    );

    /**
     * Cancels copying using given I/O vector iterator
     * (either as the iterator over the source or the
     * destination I/O vector).
     * @param iovIter A pointer to either the source or
     *   destination I/O vector iterator.
     * @return SUCCESS if the copying was terminated
     *   successfully, in which case no <tt>finishCopying</tt>
     *   event will be signaled and the caller takes
     *   back the ownership of the iterators (which
     *   can point to different positions than originally),
     *   or EINVAL if no copying with the given iterator
     *   currently takes place.
     */
    command error_t stopCopying(
            whip6_iov_blist_iter_t * iovIter
    );
    
    /**
     * Signaled when copying using given I/O vector
     * iterators has finished. The caller takes
     * back the ownership of the iterators. The iterators
     * have beed advanced by the number of copied bytes.
     * @param srcIovIter A pointer to an iterator
     *   pointing at the first byte in the source
     *   I/O vector to be read.
     * @param dstIovIter A pointer to an iterator
     *   pointing at the first byte in the destination
     *   I/O vector to be written.
     * @param numCopiedBytes The number of bytes
     *   actually copied. May be lower than the
     *   number of bytes requested to be copied.
     */
    event void finishCopying(
            whip6_iov_blist_iter_t * srcIovIter,
            whip6_iov_blist_iter_t * dstIovIter,
            size_t numCopiedBytes
    );
}
