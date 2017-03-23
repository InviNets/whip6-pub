/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

module AsyncWriteDemoPrv {
    uses interface Boot;
    uses interface Led as Green;
    uses interface Led as Orange;
    uses interface Led as Red;
    uses interface Led as Yellow;
    uses interface Timer<TMilli, uint32_t> as Timer1;
    uses interface Timer<TMilli, uint32_t> as Timer2;
    uses interface AsyncWrite<uint8_t>;
}

implementation {
    uint8_t m_val;
    error_t m_result;

    event void Boot.booted() {
        call Green.off();
        call Orange.off();
        call Red.off();
        call Yellow.off();
        m_val = 'a' - 1;
        call Timer1.startWithTimeoutFromNow(1048);
    }

    event void Timer1.fired() {
        m_val += 1;
        m_result = call AsyncWrite.startWrite(m_val);
        if (m_result != SUCCESS) {
            call Orange.on();
        }
    }

    event void Timer2.fired() {
        uint8_t locVal = 'a';
        m_val += 1;

        call Yellow.on();

        do {
            do {
                m_result = call AsyncWrite.startWrite(locVal);
            } while (m_result != SUCCESS);
            locVal += 1;
        } while (locVal <= 'z');

        call Green.on();
    }

    async event void AsyncWrite.writeDone(error_t result) {
        if (result != SUCCESS) {
            call Red.on();
        }
        if (m_val < 'z') {
            call Timer1.startWithTimeoutFromLastTrigger(32);
        } else if (m_val == 'z') {
            call Timer2.startWithTimeoutFromNow(1048);
        }
    }
}
