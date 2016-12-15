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


#include "DimensionTypes.h"

configuration QueuePrintControllerPub
{
    uses interface Init as PrintStates;
}
implementation
{
    components QueuePrintControllerPrv;
    PrintStates = QueuePrintControllerPrv.PrintStates;

    components new PlatformTimerMilliPub() as T1;
    QueuePrintControllerPrv.Timer -> T1;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[15] -> QueuePrintControllerPrv.Init;
}

