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

generic module IOVToDiscreteStreamWriterAdapterPub() {
    provides interface DiscreteStreamWriter;
    uses interface IOVWrite;
}
implementation {
    inline command error_t DiscreteStreamWriter.startWritingDataUnit(
            whip6_iov_blist_t* iov, size_t size) {
        return call IOVWrite.startWrite(iov, size);
    }

    inline event void IOVWrite.writeDone(error_t result, whip6_iov_blist_t* iov,
            uint16_t size) {
        signal DiscreteStreamWriter.finishedWritingDataUnit(iov, size, result);
    }

    default inline event void DiscreteStreamWriter.finishedWritingDataUnit(
            whip6_iov_blist_t * iov, size_t size, error_t status) { }
}
