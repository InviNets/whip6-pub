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
#include <ipv6/ucIpv6Checksum.h>



/**
 * A computer of Internet checksums for
 * potentially long I/O vectors.
 *
 * @author Konrad Iwanicki
 */
interface IPv6ChecksumComputer
{
    /**
     * Stars computing a checksum.
     * @param checksumPtr A pointer to the structure
     *   that will hold the checksum. The structure
     *   has to be initialized externally. It may
     *   already contain some bytes. As a result of the
     *   computation, it will contain the iterated over
     *   bytes. The structure should also be maintained
     *   externally during the computation (i.e., it should
     *   not reside on the stack).
     * @param iovIter An iterator pointing to the place
     *   in the I/O vector at which the computation should
     *   start. The I/O vector should be externally maintained.
     *   As a result of the computation, the iterator will
     *   be advanced by the number of bytes over which the
     *   checksum has been computed.
     * @param numBytes The number of bytes over which the
     *   checksum should be computed.
     * @return SUCCESS if the computation has been started
     *   successfully, in which case the
     *   <tt>finishChecksumming</tt> is guaranteed
     *   to be signaled; an error code otherwise, in which case
     *   no <tt>finishChecksumming</tt> will be signaled.
     *   Possible error codes:
     *     ENOMEM if there is no memory to perform the computation;
     *     EBUSY if another computation is in progress;
     *     EINVAL if the arguments are invalid.
     */
    command error_t startChecksumming(
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t numBytes
    );

    /**
     * Signaled when computing a checksum has finished.
     * @param checksumPtr A pointer to the structure
     *   holds the checksum.
     * @param iovIter An iterator pointing to the first
     *   byte in the I/O vector after the bytes that
     *   contributed to the checksum in the computation.
     *   May be invalid if the entire I/O vector was
     *   iterated over.
     * @param checksummedBytes The number of bytes over
     *   which the checksum was actually computed. May be
     *   smaller than <tt>numBytes</tt> given in
     *   <tt>startChecksumming</tt> if the I/O vector was
     *   shorter.
     */
    event void finishChecksumming(
            ipv6_checksum_computation_t * checksumPtr,
            iov_blist_iter_t * iovIter,
            size_t checksummedBytes
    );
}
