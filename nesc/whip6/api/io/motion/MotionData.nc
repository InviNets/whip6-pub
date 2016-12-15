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


#include <MotionDataTypes.h>

interface MotionData<data_type_t, dimensions_tag> {
    command error_t get(data_type_t* data, int8_t* accuracy,
            uint32_t* timestamp);
}
