/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

configuration HplUARTInterruptsPub {
    provides interface ExternalEvent as UART0Interrupt;
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as UART0Event;
    UART0Event.InterruptSource -> Sources.UART0;
    UART0Interrupt = UART0Event;
}
