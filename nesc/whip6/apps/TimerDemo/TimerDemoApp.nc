/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * An application demonstrating the timer
 * functionality.
 *
 * @author Konrad Iwanicki
 */
configuration TimerDemoApp
{
}
implementation
{
    components BoardStartupPub;
    components new PlatformTimerMilliPub() as TimerOnePrv;
    components new PlatformTimerMilliPub() as TimerTwoPrv;
    components new PlatformTimerMilliPub() as TimerThreePrv;
    components TimerDemoPrv as AppPrv;
    AppPrv.Boot -> BoardStartupPub;
    AppPrv.TimerOne -> TimerOnePrv;
    AppPrv.TimerTwo -> TimerTwoPrv;
    AppPrv.TimerThree -> TimerThreePrv;
}
