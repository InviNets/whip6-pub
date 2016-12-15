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
 
configuration HplDMAInterruptsPub {
    provides interface ExternalEvent as SwInt;
    provides interface ExternalEvent as ErrInt;
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as SwIntEvent;
    SwIntEvent.InterruptSource -> Sources.UDMA;
    SwInt = SwIntEvent;

    components new HplSimpleInterruptEventPrv() as ErrIntEvent;
    ErrIntEvent.InterruptSource -> Sources.UDMAErr;
    ErrInt = ErrIntEvent;
}
