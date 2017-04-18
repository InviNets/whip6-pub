/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


module SCIFPowerTestPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface OnOffSwitch as SCOnOff;
}

implementation {
    event void Boot.booted() {
        call Timer.startWithTimeoutFromNow(1024);
    }

    event void Timer.fired() {
        call SCOnOff.on();
    }
}
