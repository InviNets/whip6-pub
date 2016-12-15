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


#include <inc/hw_types.h>
#include <inc/hw_rfc_dbell.h>
#include <driverlib/ioc.h>

generic module RFCoreGPOSignalPrv(uint8_t signal) {
    uses interface CC26xxPin @exactlyonce();
    uses interface RFCoreGPO @exactlyonce();
    uses interface RFCorePowerUpHook @exactlyonce();
}

implementation {
    command void CC26xxPin.configure() {
        IOCPortConfigureSet(call CC26xxPin.IOId(), call RFCoreGPO.PortId(),
                IOC_STD_OUTPUT);
    }

    event void RFCorePowerUpHook.poweredUp() {
        HWREG(RFC_DBELL_BASE + RFC_DBELL_O_SYSGPOCTL) =
            HWREG(RFC_DBELL_BASE + RFC_DBELL_O_SYSGPOCTL)
            & (~(0xf << (4 * call RFCoreGPO.gpoId())))
            | ((signal & 0xf) << (4 * call RFCoreGPO.gpoId()));
    }
}
