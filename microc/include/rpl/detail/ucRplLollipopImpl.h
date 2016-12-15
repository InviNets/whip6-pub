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

#ifndef __WHIP6_MICROC_RPL_DETAIL_RPL_LOLLIPOP_IMPL_H__
#define __WHIP6_MICROC_RPL_DETAIL_RPL_LOLLIPOP_IMPL_H__

#ifndef __WHIP6_MICROC_RPL_RPL_LOLLIPOP_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_RPL_RPL_LOLLIPOP_H__ */


enum
{
    WHIP6_RPL_LOLLIPOP_MAX_TOTAL_VALUE = 255,
    WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE = 127,
    WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW = 16,
};


WHIP6_MICROC_INLINE_DEF_PREFIX rpl_lollipop_counter_t whip6_rplLollipopGetInitialValue(
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return WHIP6_RPL_LOLLIPOP_MAX_TOTAL_VALUE - WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW + 1;
}



WHIP6_MICROC_INLINE_DEF_PREFIX rpl_lollipop_counter_t whip6_rplLollipopGetIncrementedValue(
        rpl_lollipop_counter_t counter
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return counter > WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE ?
            ((counter + 1) & WHIP6_RPL_LOLLIPOP_MAX_TOTAL_VALUE) :
            ((counter + 1) & WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE);
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX int8_t whip6_rplLollipopAreValuesComparable(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if (counter1 <= WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
    {
        if (counter2 <= WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
        {
            goto COUNTERS_IN_SAME_REGION;
        }
    }
    else
    {
        if (counter2 > WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
        {
            goto COUNTERS_IN_SAME_REGION;
        }
    }
    return 1;

COUNTERS_IN_SAME_REGION:
    if (counter1 < counter2)
    {
        if (counter2 - counter1 > WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW)
        {
            return 0;
        }
    }
    else
    {
        if (counter1 - counter2 > WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW)
        {
            return 0;
        }
    }
    return 1;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX int8_t whip6_rplLollipopIsOneValueGreaterThanAnother(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    if (counter1 > WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
    {
        if (counter2 > WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
        {
            goto COUNTERS_IN_SAME_REGION;
        }
        else
        {
            return ((WHIP6_RPL_LOLLIPOP_MAX_TOTAL_VALUE - counter1) + counter2 + 1 > WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW) ? 1 : 0;
        }
    }
    else
    {
        if (counter2 <= WHIP6_RPL_LOLLIPOP_MAX_CIRCULAR_REGION_VALUE)
        {
            goto COUNTERS_IN_SAME_REGION;
        }
        else
        {
            return ((WHIP6_RPL_LOLLIPOP_MAX_TOTAL_VALUE - counter2) + counter1 + 1 <= WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW) ? 1 : 0;
        }
    }
    return 0;

COUNTERS_IN_SAME_REGION:
    return (counter1 > counter2 && counter1 - counter2 <= WHIP6_RPL_LOLLIPOP_SEQUENCE_WINDOW) ? 1 : 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_rplLollipopIsOneValueEqualToAnother(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return counter1 == counter2 ? 1 : 0;
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_rplLollipopCompareValues(
        rpl_lollipop_counter_t counter1,
        rpl_lollipop_counter_t counter2
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    if (whip6_rplLollipopIsOneValueEqualToAnother(counter1, counter2))
    {
        return 0;
    }
    return whip6_rplLollipopIsOneValueGreaterThanAnother(counter1, counter2) ? (int8_t)1 : (int8_t)-1;
}


#endif /* __WHIP6_MICROC_RPL_DETAIL_RPL_LOLLIPOP_IMPL_H__ */
