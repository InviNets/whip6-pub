/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

#include "Assert.h"
#include "IOMuxPrv.h"

generic module IOVToPacketWriterAdapterPub() {
    provides interface PacketWrite;
    uses interface IOVWrite;
}
implementation {
    whip6_iov_blist_t iov;

    command error_t PacketWrite.startWrite(uint8_t_xdata *buffer,
            uint16_t size) {
        if (buffer == NULL)
            return EINVAL;
        if (iov.iov.ptr != NULL)
            return EBUSY;
        iov.iov.ptr = buffer;
        iov.iov.len = size;
        return call IOVWrite.startWrite(&iov, size);
    }

    event void IOVWrite.writeDone(error_t result, whip6_iov_blist_t* done_iov,
            uint16_t size) {
        uint8_t_xdata* buf = iov.iov.ptr;
        CHECK(done_iov == &iov);
        iov.iov.ptr = NULL;
        signal PacketWrite.writeDone(result, buf, size);
    }

    default inline event void PacketWrite.writeDone(error_t result, uint8_t_xdata* buffer, uint16_t size) { }
}
