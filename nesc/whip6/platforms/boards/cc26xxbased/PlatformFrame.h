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

#ifndef PLATFORM_FRAME_H
#define PLATFORM_FRAME_H

#ifdef PLATFORM_MAX_PAYLOAD
#error PLATFORM_MAX_PAYLOAD already defined, fix the order of includes
#endif

#define PLATFORM_MAX_PAYLOAD 125

#include <RFCoreFrame.h>
#include <Ieee154.h>

typedef struct _platform_frame_s {
    rfcore_frame_t          rfcore_frame;
    ieee154_dframe_info_t   dframe_info;
} platform_frame_t;

#endif
