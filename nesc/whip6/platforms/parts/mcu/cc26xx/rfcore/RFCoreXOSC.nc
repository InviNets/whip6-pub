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


/*
 * The radio is the only CC26xx subsystem, which really requires XOSC.
 * Initially, for simplicity (and to avoid synchronizing the HF RCOSC),
 * we keep the XOSC always running and wire the RFCoreDummyXOSCPrv
 * to the radio driver.
 *
 * In the future another implementation may be provided which keeps the
 * XOSC on only when absolutely needed.
 */

interface RFCoreXOSC {
    command void requestXOSC();
    command void switchToXOSC();
    command void releaseXOSC();
}
