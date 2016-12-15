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
 * Reading to IOVs.
 *
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
interface IOVRead {
    /**
     * Starts reading. Packets bigger than <tt>max_size</tt> will be silently
     * dropped.
     *
     * @return EBUSY if reading already started, EINVAL if <tt>max_size</tt> is
     *         zero, SUCCESS otherwise.
     */
    command error_t startRead(uint16_t max_size);

    /**
     * Event generated whan an IOV is to be allocated and its required size
     * is known.
     *
     * If this event returns NULL, reading of this packet is terminated and
     * another packet is being awaited. No need to call <tt>startRead</tt>
     * again in this case.
     */
    event whip6_iov_blist_t* requestIOV(uint16_t size);

    /**
     * Reports that read has completed successfully.
     *
     * To begin another read, <tt>startRead</tt> must be called.
     *
     * @param iov  the iov returned by <tt>requestIOV</tt> previously
     * @param size the size of the packet (same as passed to
     *             <tt>requestIOV</tt>)
     */
    event void readDone(whip6_iov_blist_t* iov, uint16_t size);
}
