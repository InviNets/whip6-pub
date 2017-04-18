/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>


/**
 * Writing from IOVs.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
interface IOVWrite {
    /**
     * Begins writing an IOV.
     *
     * @return SUCCESS if IOV will eventually be written,
     *         EINVAL if <tt>iov</tt> is NULL or empty,
     *         EBUSY if another write is already in progress.
     */
    command error_t startWrite(whip6_iov_blist_t* iov, uint16_t size);

    /**
     * Reports that writing is complete.
     */
    event void writeDone(error_t result, whip6_iov_blist_t* iov, uint16_t size);
}
