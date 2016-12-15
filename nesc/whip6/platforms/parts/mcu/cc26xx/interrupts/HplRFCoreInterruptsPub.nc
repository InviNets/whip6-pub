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

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

configuration HplRFCoreInterruptsPub {
    provides interface ExternalEvent as RFCCPE0;
    provides interface ExternalEvent as RFCCPE1;
    provides interface ExternalEvent as RFCHw;
    provides interface ExternalEvent as RFCAck;
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as CPE0Event;
    CPE0Event.InterruptSource -> Sources.RFCCPE0;
    RFCCPE0 = CPE0Event;
    components new HplSimpleInterruptEventPrv() as CPE1Event;
    CPE1Event.InterruptSource -> Sources.RFCCPE1;
    RFCCPE1 = CPE1Event;
    components new HplSimpleInterruptEventPrv() as HwEvent;
    HwEvent.InterruptSource -> Sources.RFCHw;
    RFCHw = HwEvent;
    components new HplSimpleInterruptEventPrv() as AckEvent;
    AckEvent.InterruptSource -> Sources.RFCAck;
    RFCAck = AckEvent;
}
