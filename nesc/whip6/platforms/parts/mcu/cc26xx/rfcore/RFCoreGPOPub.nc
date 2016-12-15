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


#include "hal_timer_resources.h"

generic configuration RFCoreGPOPub() {
    provides interface RFCoreGPO @atmostonce();
}
implementation {
    enum {
        RESOURCE_ID = unique(RESOURCE_HAL_RFCORE_GPO),
    };

    components RFCoreGPOsPrv;
    RFCoreGPO = RFCoreGPOsPrv.RFCoreGPO[RESOURCE_ID];
}
