/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <stdio.h>



/**
 * The main module of an application demonstrating
 * the timer functionality.
 *
 * @author Konrad Iwanicki
 */
module TimerDemoPrv
{
    uses
    {
        interface Boot;
        interface Timer<TMilli, uint32_t> as TimerOne;
        interface Timer<TMilli, uint32_t> as TimerTwo;
        interface Timer<TMilli, uint32_t> as TimerThree;
    }    
}
implementation
{
    task void setupTimersTask()
    {
        call TimerOne.startWithTimeoutFromNow(1024UL);
        call TimerTwo.startWithTimeoutFromNow(4096UL);
        call TimerThree.startWithTimeoutFromNow(16384UL);
    }

    event void TimerOne.fired()
    {
        printf("Timer 1 fired.\r\n");
        call TimerOne.startWithTimeoutFromNow(1024UL);
    }

    event void TimerTwo.fired()
    {
        printf("Timer 2 fired.\r\n");
        call TimerTwo.startWithTimeoutFromLastTrigger(4096UL);
    }

    event void TimerThree.fired()
    {
        printf("Timer 3 fired.\r\n");
        call TimerThree.startWithTimeoutFromNow(16384UL);
    }

    event void Boot.booted()
    {
        post setupTimersTask();
    }
}
