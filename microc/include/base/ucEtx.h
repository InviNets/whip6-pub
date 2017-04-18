/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_BASE_ETX_H__
#define __WHIP6_MICROC_BASE_ETX_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains the types and operations for the
 * estimated transmissions (ETX) routing metric and
 * related metrics, such as packet reception rate (PRR).
 *
 */

#include <base/ucTypes.h>


/** The ETX metric in the host byte order. */
typedef uint16_t   etx_metric_host_t;
typedef uint32_t   etx_sqr_metric_host_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(etx_metric_host_t)



/** The PRR metric in the host byte order. */
typedef uint8_t    prr_metric_host_t;
typedef uint16_t   prr_sqr_metric_host_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(prr_metric_host_t)


enum
{
    WHIP6_ETX_METRIC_TOTAL_BITS = 16,
    WHIP6_ETX_METRIC_FRACTIONAL_BITS = 4,
    WHIP6_ETX_METRIC_BIT_SHIFT = WHIP6_ETX_METRIC_FRACTIONAL_BITS,
};

enum
{
    WHIP6_ETX_METRIC_ZERO = 0,
    WHIP6_ETX_METRIC_ONE = (1 << WHIP6_ETX_METRIC_BIT_SHIFT),
    WHIP6_ETX_METRIC_INFINITE = 0xffff,
};

enum
{
    WHIP6_PRR_METRIC_ZERO = 0,
    WHIP6_PRR_METRIC_ONE = 0xff,
};


/**
 * Converts a PRR value into an ETX value.
 * @param prr The PRR value.
 * @return The ETX value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX etx_metric_host_t whip6_metricPrrToEtx(
        prr_metric_host_t prr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Converts a PRR value into an ETX value.
 * @param prr The ETX value.
 * @return The PRR value.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX prr_metric_host_t whip6_metricEtxToPrr(
        etx_metric_host_t etx
) WHIP6_MICROC_INLINE_DECL_SUFFIX;




#define whip6_metricPrrToFloat(prr) (((float)((prr) - WHIP6_PRR_METRIC_ZERO) / (float)(WHIP6_PRR_METRIC_ONE - WHIP6_PRR_METRIC_ZERO)) * 100.0f)
#define whip6_metricEtxToFloat(etx) ((float)(etx) / (float)WHIP6_ETX_METRIC_ONE)



#include <base/detail/ucEtxImpl.h>


#endif /* __WHIP6_MICROC_BASE_ETX_H__ */
