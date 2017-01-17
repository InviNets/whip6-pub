/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 *
 */
configuration PlatformSCIFUARTPub {
    provides interface OnOffSwitch;
}
implementation {
    components new HalSCIFPub() as SCIF;

    components PlatformSCIFUARTPrv as Prv;
    Prv.SCIF -> SCIF;

    OnOffSwitch = Prv;
}
