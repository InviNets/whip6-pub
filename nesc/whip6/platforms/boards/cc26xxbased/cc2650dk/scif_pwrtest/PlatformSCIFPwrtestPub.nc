/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration PlatformSCIFPwrtestPub {
    provides interface OnOffSwitch;
}
implementation {
    components new HalSCIFPub() as SCIF;

    components PlatformSCIFPwrtestPrv as Prv;
    Prv.SCIF -> SCIF;

    OnOffSwitch = Prv;
}
