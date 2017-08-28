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

generic module ConvertedDimensionalReadPub(
        typedef from_units_tag, typedef from_val_t @integer(),
        typedef to_units_tag, typedef to_val_t @integer(),
        int postMultiplier, int postDivisor)
{
    uses interface DimensionalRead<from_units_tag, from_val_t> as From;
    provides interface DimensionalRead<to_units_tag, to_val_t> as To;
}
implementation
{
    command inline error_t To.read() {
        return call From.read();
    }

    event inline void From.readDone(error_t result, from_val_t val) {
        signal To.readDone(result, ((to_val_t)val) * postMultiplier /
                postDivisor);
    }
}
