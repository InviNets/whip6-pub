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

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include "Assert.h"

generic module IOVToPacketReaderAdapterPub() {
    provides interface PacketRead;
    uses interface IOVRead;
}
implementation {
    whip6_iov_blist_t iov;

    command error_t PacketRead.startRead(uint8_t_xdata* buffer,
            uint16_t capacity) {
        if (buffer == NULL)
            return EINVAL;
        if (iov.iov.ptr != NULL)
            return EBUSY;
        iov.iov.ptr = buffer;
        iov.iov.len = capacity;
        return call IOVRead.startRead(capacity);
    }

    inline event whip6_iov_blist_t* IOVRead.requestIOV(uint16_t size) {
        return &iov;
    }

    inline event void IOVRead.readDone(whip6_iov_blist_t* done_iov, uint16_t size) {
        uint8_t_xdata* buf = iov.iov.ptr;
        CHECK(done_iov == &iov);
        iov.iov.ptr = NULL;
        signal PacketRead.readDone(buf, size);
    }

    default inline event void PacketRead.readDone(uint8_t_xdata* buffer, uint16_t size) { }
}
