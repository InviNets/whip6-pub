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

configuration HplI2SInterruptPub {
    provides interface ExternalEvent as I2SInterrupt;
}
implementation{
    components HplCC26xxIntSrcPub as Sources;

    components new HplSimpleInterruptEventPrv() as Event;
    Event.InterruptSource -> Sources.I2S;
    I2SInterrupt = Event;
}
