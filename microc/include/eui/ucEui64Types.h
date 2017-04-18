/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_EUI_EUI64_TYPES_H__
#define __WHIP6_MICROC_EUI_EUI64_TYPES_H__

#include <base/ucTypes.h>

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains type definitions for EUI-64.
 * For more information, refer to docs/eui64.pdf.
 */


enum
{
    /** The number of bytes in IEEE EUI-64. */
    IEEE_EUI64_BYTE_LENGTH = 8,
};


/**
 * IEEE EUI-64.
 */
typedef struct ieee_eui64_s
{
    uint8_t   data[IEEE_EUI64_BYTE_LENGTH];
} MICROC_NETWORK_STRUCT ieee_eui64_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee_eui64_t)

#endif /* __WHIP6_MICROC_EUI_EUI64_TYPES_H__ */
