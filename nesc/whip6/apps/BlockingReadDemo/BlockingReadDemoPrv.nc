/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

module BlockingReadDemoPrv {
    uses interface Boot;
    uses interface Led as Green;
    uses interface Led as Orange;
    uses interface Led as Yellow;
    uses interface Timer<TMilli, uint32_t>;
    uses interface BlockingRead<uint8_t>;
}

implementation {
   uint8_t m_val;

   event void Boot.booted() {
        call Green.off();
        call Orange.off();
        call Yellow.off();
        call Timer.startWithTimeoutFromNow(2048);
   }

   event void Timer.fired() {
        call Yellow.on();
        m_val = call BlockingRead.read();
        if (m_val == 'y') {
            call Green.toggle();
        } else {
            call Orange.toggle();
        }
        call Yellow.off();
        call Timer.startWithTimeoutFromNow(2048);
   }
}
