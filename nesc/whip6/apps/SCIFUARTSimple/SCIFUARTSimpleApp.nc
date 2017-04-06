/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

configuration SCIFUARTSimpleApp {
}

implementation {
    components BoardStartupPub, SCIFUARTSimplePrv;
    SCIFUARTSimplePrv.Boot -> BoardStartupPub;

    components PlatformSCIFUARTPub as SCIF;
    SCIFUARTSimplePrv.SCOnOff -> SCIF;

    components new PlatformTimerMilliPub();
    SCIFUARTSimplePrv.Timer -> PlatformTimerMilliPub;
}
