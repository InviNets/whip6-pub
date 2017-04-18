/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_BASE_ERROR_H__
#define __WHIP6_MICROC_BASE_ERROR_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the error type and error
 * code that are used in whip6 microc functions.
 *
 */

#include <base/ucTypes.h>


/** The error type. */
typedef uint8_t   whip6_error_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(whip6_error_t)

enum
{
    /** No error. */
    WHIP6_NO_ERROR = 0,
    /** An invalid argument. */
    WHIP6_ARGUMENT_ERROR = 1,
    /** An invalid size. */
    WHIP6_SIZE_ERROR = 2,
    /** An invalid state. */
    WHIP6_STATE_ERROR = 3,
    /** An invalid checksum. */
    WHIP6_CHECKSUM_ERROR = 100,
};

#endif /* __WHIP6_MICROC_BASE_ERROR_H__ */
