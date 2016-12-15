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
 * @author Przemyslaw Horban
 * @author Michal Marschall <m.marschall@invinets.com>
 * 
 * Software reset test. The Led should blink if reset works.
 * It will stay on if it does not.
 */

module SoftResetPrv {
    uses interface Boot;
    uses interface Led;
    uses interface Reset;
    uses interface Timer<TMilli, uint32_t>;
}

implementation {
    event void Boot.booted() {
       call Led.off();
       call Timer.startWithTimeoutFromNow(1024);
    }

    event void Timer.fired() {
       call Led.on();
       // Alternatively call whip6_crashNode() or software_reset();
       call Reset.reset();
    }
}
