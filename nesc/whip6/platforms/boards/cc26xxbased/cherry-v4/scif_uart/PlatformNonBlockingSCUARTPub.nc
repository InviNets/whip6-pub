/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
generic configuration PlatformNonBlockingSCUARTPub(uint32_t baud) {
    provides {
        interface Init @exactlyonce();
        interface NonBlockingWrite<uint8_t>;
    }
} implementation {
    components new HalConfigureSCUARTPrv(baud) as CfgPrv;
    components HalUARTNonBlockingWritePrv as UARTWritePrv;
    components PlatformSCIFUARTPub as SCIF;

    CfgPrv.SCOnOff -> SCIF;

    Init = CfgPrv.Init;
    NonBlockingWrite = UARTWritePrv;
}
