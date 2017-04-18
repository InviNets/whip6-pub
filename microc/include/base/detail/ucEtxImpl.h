/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_BASE_DETAIL_ETX_IMPL_H__
#define __WHIP6_MICROC_BASE_DETAIL_ETX_IMPL_H__

#ifndef __WHIP6_MICROC_BASE_ETX_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_BASE_ETX_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX etx_metric_host_t whip6_metricPrrToEtx(
        prr_metric_host_t prr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    etx_metric_host_t   etx;
    if (prr <= WHIP6_PRR_METRIC_ZERO)
    {
        return WHIP6_ETX_METRIC_INFINITE;
    }
    etx = WHIP6_PRR_METRIC_ONE - WHIP6_PRR_METRIC_ZERO;
    etx *= WHIP6_ETX_METRIC_ONE;
    etx /= prr - WHIP6_PRR_METRIC_ZERO;
    return etx;

}



WHIP6_MICROC_INLINE_DEF_PREFIX prr_metric_host_t whip6_metricEtxToPrr(
        etx_metric_host_t etx
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    etx_metric_host_t   newEtx;
    if (etx <= WHIP6_ETX_METRIC_ONE)
    {
        return WHIP6_PRR_METRIC_ONE;
    }
    else if (etx >= WHIP6_ETX_METRIC_INFINITE)
    {
        return WHIP6_PRR_METRIC_ZERO;
    }
    newEtx = WHIP6_PRR_METRIC_ONE - WHIP6_PRR_METRIC_ZERO;
    newEtx *= WHIP6_ETX_METRIC_ONE;
    newEtx /= etx;
    return (prr_metric_host_t)newEtx + WHIP6_PRR_METRIC_ZERO;
}



#endif /* __WHIP6_MICROC_BASE_DETAIL_ETX_IMPL_H__ */
