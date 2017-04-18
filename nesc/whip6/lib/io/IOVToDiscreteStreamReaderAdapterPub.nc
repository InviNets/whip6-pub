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

generic module IOVToDiscreteStreamReaderAdapterPub() {
    provides interface DiscreteStreamReader;
    uses interface IOVRead;
}
implementation {
    inline command error_t DiscreteStreamReader.startReadingDataUnit(size_t maxSize) {
        return call IOVRead.startRead(maxSize);
    }

    inline event whip6_iov_blist_t* IOVRead.requestIOV(uint16_t size) {
        return signal DiscreteStreamReader.provideIOVForDataUnit(size);
    }

    inline event void IOVRead.readDone(whip6_iov_blist_t* done_iov, uint16_t size) {
        signal DiscreteStreamReader.finishedReadingDataUnit(
                done_iov,
                size,
                size > 0 ? SUCCESS : ERETRY
        );
    }

    default inline event void DiscreteStreamReader.finishedReadingDataUnit(
        whip6_iov_blist_t* iov, size_t size, error_t status) { }
}
