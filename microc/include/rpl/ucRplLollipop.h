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

#ifndef __WHIP6_MICROC_RPL_RPL_LOLLIPOP_H__
#define __WHIP6_MICROC_RPL_RPL_LOLLIPOP_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains function for manipulating RPL lollipop counters.
 * For more information, refer to docs/rfc-6550.pdf.
 */

#include <base/ucTypes.h>
#include <rpl/ucRplBase.h>



/**
 * Returns an initial value of RPL's lollipop counter.
 * @return The initial lollipop counter value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX rpl_lollipop_counter_t whip6_rplLollipopGetInitialValue(
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Increments RPL's lollipop counter by one.
 * @param counter The current counter value.
 * @return The incremented counter value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX rpl_lollipop_counter_t whip6_rplLollipopGetIncrementedValue(
        rpl_lollipop_counter_t counter
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if two RPL's lollipop counters are comparable.
 * @param counter1 The first counter.
 * @param counter2 The second counter.
 * @return Nonzero if the values are comparable or zero
 *   otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX int8_t whip6_rplLollipopAreValuesComparable(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if one RPL's lollipop counter is greater than another.
 * @param counter1 The first counter.
 * @param counter2 The second counter.
 * @return Nonzero if the first counter is greater than
 *   the second one or zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DECL_PREFIX int8_t whip6_rplLollipopIsOneValueGreaterThanAnother(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_PRIVATE_DECL_SUFFIX;

/**
 * Checks if two RPL's lollipop counters are equal.
 * @param counter1 The first counter.
 * @param counter2 The second counter.
 * @return Nonzero if the first counter is equal to
 *   the second one or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_rplLollipopIsOneValueEqualToAnother(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Compares two RPL's lollipop counters. Assumes that
 * the counter values are comparable. If they are not,
 * the result of the function is undefined but
 * deterministic.
 * @param counter1 The first counter.
 * @param counter2 The second counter.
 * @return Zero if the counters are equal; a negative value if
 *   the first counter is smaller than the second one;
 *   a positive value if the first counter is greater than
 *   the second one.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_rplLollipopCompareValues(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


#include <rpl/detail/ucRplLollipopImpl.h>

#endif /* __WHIP6_MICROC_RPL_RPL_LOLLIPOP_H__ */
