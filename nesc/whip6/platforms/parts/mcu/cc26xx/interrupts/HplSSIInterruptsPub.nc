/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */
 
configuration HplSSIInterruptsPub {
    provides interface ExternalEvent as SSI0Interrupt;
    provides interface ExternalEvent as SSI1Interrupt;
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as SSI0Event;
    SSI0Event.InterruptSource -> Sources.SSI0;
    SSI0Interrupt = SSI0Event;

    components new HplSimpleInterruptEventPrv() as SSI1Event;
    SSI1Event.InterruptSource -> Sources.SSI1;
    SSI1Interrupt = SSI1Event;
}
