/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


module RFCoreDummyXOSCPrv {
    provides interface RFCoreXOSC;
}
implementation {
    command void RFCoreXOSC.requestXOSC() { }
    command void RFCoreXOSC.switchToXOSC() { }
    command void RFCoreXOSC.releaseXOSC() { }
}
