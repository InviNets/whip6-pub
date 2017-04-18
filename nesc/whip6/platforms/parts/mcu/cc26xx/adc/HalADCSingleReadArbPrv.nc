/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include "DimensionTypes.h"
#include "hal_adc.h"

configuration HalADCSingleReadArbPrv {
    provides interface Resource[uint8_t userId];
    provides interface ArbiterInfo;
    provides interface DimensionalRead<TMilliVolt, int16_t> as ReadSource[uint8_t userId, uint8_t port];
}

implementation {
    components HalADCSingleReadPrv;
    ReadSource = HalADCSingleReadPrv.ReadSource;
    
    components new SimpleFcfsArbiterPub(HAL_ADC_RESOURCE) as Arbiter;
    HalADCSingleReadPrv.ArbiterInfo -> Arbiter;
    Resource = Arbiter;
    ArbiterInfo = Arbiter;
}
