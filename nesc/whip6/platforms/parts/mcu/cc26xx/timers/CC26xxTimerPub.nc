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

generic configuration CC26xxTimerPub() {
    provides interface CC26xxTimer @atmostonce();
    provides interface ExternalEvent as ChannelAInterrupt @atmostonce();
    provides interface ExternalEvent as ChannelBInterrupt @atmostonce();
}
implementation {
    enum {
        RESOURCE_ID = unique(RESOURCE_HAL_TIMER),
    };

    components CC26xxTimersPrv;
    CC26xxTimer = CC26xxTimersPrv.CC26xxTimer[RESOURCE_ID];

    components HplTimerInterruptsPub;
    ChannelAInterrupt = HplTimerInterruptsPub.ChannelAInterrupt[RESOURCE_ID];
    ChannelBInterrupt = HplTimerInterruptsPub.ChannelBInterrupt[RESOURCE_ID];
}
