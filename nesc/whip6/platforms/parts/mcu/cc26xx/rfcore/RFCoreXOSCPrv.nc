/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <driverlib/osc.h>

module RFCoreXOSCPrv {
    provides interface RFCoreXOSC;
}
implementation {
    command void RFCoreXOSC.requestXOSC() {
        OSCHF_TurnOnXosc();
    }

    command void RFCoreXOSC.switchToXOSC() {
        while (!OSCHF_AttemptToSwitchToXosc()) /* nop */;
    }

    command void RFCoreXOSC.releaseXOSC() {
        OSCHF_SwitchToRcOscTurnOffXosc();
    }
}
