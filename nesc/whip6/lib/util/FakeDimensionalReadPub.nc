/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 */
 
generic module FakeDimensionalReadPub(typedef read_units, typedef read_type @integer(), int defValue) {
    provides interface DimensionalRead<read_units, read_type>;
}
implementation{
    task void signalReadDone() {
        signal DimensionalRead.readDone(SUCCESS, defValue);
    }

    command error_t DimensionalRead.read() {
        post signalReadDone();
        return SUCCESS;
    }
}
