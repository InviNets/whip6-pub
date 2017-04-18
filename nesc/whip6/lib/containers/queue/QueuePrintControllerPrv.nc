/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


module QueuePrintControllerPrv
{
    uses interface Init as PrintStates;
    provides interface Init;
    uses interface Timer<TMilli, uint32_t>;
}
implementation
{
    command error_t Init.init() {
        call Timer.startWithTimeoutFromNow(1000);
    }

    event void Timer.fired() {
        call PrintStates.init();
        call Timer.startWithTimeoutFromNow(1000);
    }
}
