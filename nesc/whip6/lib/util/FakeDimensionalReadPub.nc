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
 * @author Przemyslaw Horban <extremegf@gmail.com>
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

