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

#ifndef __WHIP6_MICROC_BASE_STRING_H__
#define __WHIP6_MICROC_BASE_STRING_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the basic string operations.
 *
 */

#include <base/ucTypes.h>



WHIP6_MICROC_PRIVATE_DECL_PREFIX char __whip6_lo4bitsToHexChar(
        uint8_t b
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_shortMemCpy(
        uint8_t MCS51_STORED_IN_RAM const * src,
        uint8_t MCS51_STORED_IN_RAM * dst,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_shortMemSet(
        uint8_t MCS51_STORED_IN_RAM * m,
        uint8_t pattern,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

WHIP6_MICROC_PRIVATE_DECL_PREFIX int8_t whip6_shortMemCmp(
        uint8_t MCS51_STORED_IN_RAM const * m1,
        uint8_t MCS51_STORED_IN_RAM const * m2,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

WHIP6_MICROC_PRIVATE_DECL_PREFIX void whip6_longMemCpy(
        uint8_t MCS51_STORED_IN_RAM const * src,
        uint8_t MCS51_STORED_IN_RAM * dst,
        size_t size
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;



/**
 * Converts the lower four bits of a given byte
 * into a lower-case hexadecimal character.
 * @param b The input byte.
 * @return A character 0-9a-f corresponding to
 *   the four lower bits of the input byte.
 */
#define whip6_lo4bitsToHexChar(b) __whip6_lo4bitsToHexChar(b)

/**
 * Converts the upper four bits of a given byte
 * into a lower-case hexadecimal character.
 * @param b The input byte.
 * @return A character 0-9a-f corresponding to
 *   the four lower bits of the input byte.
 */
#define whip6_hi4bitsToHexChar(b) __whip6_lo4bitsToHexChar((b) >> 4)



#include <base/detail/ucStringImpl.h>

#endif /* __WHIP6_MICROC_BASE_STRING_H__ */
