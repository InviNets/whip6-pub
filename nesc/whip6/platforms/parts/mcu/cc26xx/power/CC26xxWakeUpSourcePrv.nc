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

/**
 * @author Szymon Acedanski
 */

#include "aon_event.h"

generic module CC26xxWakeUpSourcePrv(uint32_t channel, uint32_t source) {
    provides interface CC26xxWakeUpSource @atmostonce();
}
implementation
{
    command void CC26xxWakeUpSource.enableWakeUp() {
        if (channel >= 4) {
            // There are only 4 wakeup channels...
            panic();
        }
        AONEventMcuWakeUpSet(channel, source);
    }

    command void CC26xxWakeUpSource.disableWakeUp() {
        AONEventMcuWakeUpSet(channel, AON_EVENT_NONE);
    }
}
