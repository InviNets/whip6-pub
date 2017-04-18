/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <MotionDataTypes.h>

interface MotionData<data_type_t, dimensions_tag> {
    command error_t get(data_type_t* data, int8_t* accuracy,
            uint32_t* timestamp);
}
