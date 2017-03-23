/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

module AsyncReadDemoPrv {
    uses interface Boot;
    uses interface Led as Green;
    uses interface Led as Orange;
    uses interface Led as Red;
    uses interface Led as Yellow;
    uses interface Timer<TMilli, uint32_t>;
    uses interface ReadNow<uint8_t>;
}

implementation {
    uint8_t m_locVal;

    event void Boot.booted() {
        call Green.off();
        call Orange.off();
        call Red.off();
        call Yellow.off();
        m_locVal = 'b';
        call Timer.startWithTimeoutFromNow(2048);
    }

    event void Timer.fired() {
        error_t result;

        result = call ReadNow.read();

        if (result != SUCCESS) {
            call Red.on();
        }
        if (m_locVal == 'a') {
                atomic {
                    m_locVal = 'b';
                    call Yellow.off();
                }
        } else {
                atomic {
                    m_locVal = 'a';
                    call Yellow.on();
                }
        }
        call Timer.startWithTimeoutFromLastTrigger(3072);
    }

    async event void ReadNow.readDone(error_t result, uint8_t val) {
        if (result == SUCCESS) {
            call Orange.toggle();
            if (val == m_locVal) {
                call Green.toggle();
            }
        } else {
            call Red.on();
        }
    }
}
