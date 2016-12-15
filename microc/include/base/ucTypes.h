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

#ifndef __WHIP6_MICROC_BASE_TYPES_H__
#define __WHIP6_MICROC_BASE_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the basic types used
 * in every whip6 microc file.
 *
 */

#include <stddef.h>
#include <stdint.h>

#if defined (__SDCC_mcs51)
#define MCS51_STORED_IN_RAM __xdata
#define MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(type)
#else
#define MCS51_STORED_IN_RAM
#define MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(type)
#endif

#if defined (__SDCC_mcs51)
#define MICROC_NETWORK_STRUCT
#else
#define MICROC_NETWORK_STRUCT __attribute__((packed))
#endif

#endif /* __WHIP6_MICROC_BASE_TYPES_H__ */
