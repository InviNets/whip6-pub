/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <driverlib/ioc.h>

configuration RFCoreGPOsPrv {
    provides interface RFCoreGPO[uint8_t num];
}
implementation {
    components new RFCoreGPOPrv(0, IOC_PORT_RFC_GPO0) as GPO0;
    RFCoreGPO[0] = GPO0.RFCoreGPO;
    components new RFCoreGPOPrv(1, IOC_PORT_RFC_GPO1) as GPO1;
    RFCoreGPO[1] = GPO1.RFCoreGPO;
    components new RFCoreGPOPrv(2, IOC_PORT_RFC_GPO2) as GPO2;
    RFCoreGPO[2] = GPO2.RFCoreGPO;
    components new RFCoreGPOPrv(3, IOC_PORT_RFC_GPO3) as GPO3;
    RFCoreGPO[3] = GPO3.RFCoreGPO;
}
