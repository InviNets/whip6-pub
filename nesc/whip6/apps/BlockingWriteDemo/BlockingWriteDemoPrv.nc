/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

module BlockingWriteDemoPrv {
    uses interface Boot;
    uses interface Led as Green;
    uses interface Led as Orange;
    uses interface Led as Red;
    uses interface Led as Yellow;
    uses interface Timer<TMilli, uint32_t> as Timer1;
    uses interface Timer<TMilli, uint32_t> as Timer2;
    uses interface BlockingWrite<uint8_t>;
}

implementation {
    uint8_t val;
    error_t result;

    event void Boot.booted() {
        call Green.off();
        call Orange.off();
        call Red.off();
        call Yellow.off();
        val = 'a';
        call Timer1.startWithTimeoutFromNow(1048);
   }

   event void Timer1.fired() {
        call Yellow.on();
        result = call BlockingWrite.write(val);
        if (result == SUCCESS) {
            call Green.toggle();
        } else {
            call Red.on();
        }
        if (val == 'z') {
            call Yellow.off();
            call Timer2.startWithTimeoutFromNow(1048);
        } else {
            val = val + 1;
            call Timer1.startWithTimeoutFromLastTrigger(512);
        }
   }

   event void Timer2.fired() {
        call Orange.on();
        result = SUCCESS;
        val = 'a' - 1;

        do {
            val += 1;
            result = call BlockingWrite.write(val);
        } while (val != 'z' && result == SUCCESS);

        call Orange.off();
   }
}
