/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
