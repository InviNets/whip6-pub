/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
