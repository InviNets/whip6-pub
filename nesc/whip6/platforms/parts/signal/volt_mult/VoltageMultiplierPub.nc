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
 * 
 * Converts the voltage by multiplying it by numerator/denominator.
 * Watch out for overflow!
 */
 
#include "DimensionTypes.h"

generic module VoltageMultiplierPub(int32_t numerator, int32_t denominator)  {
    uses interface DimensionalRead<TMilliVolt, int16_t> as Input;
    provides interface DimensionalRead<TMilliVolt, int16_t> as Output;
}
implementation {
    command error_t Output.read(){
        return call Input.read();
    }

    event void Input.readDone(error_t result, int16_t val){
        int32_t x = val;
        x = (x * numerator) / denominator;
        signal Output.readDone(result, (int16_t)x);
    }
}
