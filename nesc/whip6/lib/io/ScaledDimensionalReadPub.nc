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
 * @author Szymon Acedanski
 * 
 * A unit converter for DimensionalRead.
 */

generic module ScaledDimensionalReadPub(typedef units_tag,
        typedef val_t @integer(), int multiplier, int divisor)
{
    uses interface DimensionalRead<units_tag, val_t> as From;
    provides interface DimensionalRead<units_tag, val_t> as To;
}
implementation
{
    command inline error_t To.read() {
        return call From.read();
    }

    event inline void From.readDone(error_t result, val_t val) {
        signal To.readDone(result, val * multiplier / divisor);
    }
}
