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

module TestResultNotifyPub {
    uses interface Led;
    uses interface Timer<TMilli, uint32_t>;

    provides interface TestResultNotify;
} implementation{
    enum {
        IDLE,
        LONG_BLINK,
        SHORT_OFF,
        PAUSE_OFF,
        FSHORT_ON,
        FSHORT_OFF
    };

    uint8_t state = IDLE;
    uint8_t failNr;
    uint8_t blinksLeft;

    void passLongOnStart();
    void passShortOff();
    void failPauseStart();
    void failNrCycleStart();
    void failBlink();

    command void TestResultNotify.testsPassed() {
        if (state != IDLE) {
            return;
        }
        passLongOnStart();
    }

    void passLongOnStart() {
        call Timer.startWithTimeoutFromNow(3000);
        call Led.on();
        state = LONG_BLINK;
    }

    void passShortOff() {
        call Timer.startWithTimeoutFromNow(3000);
        call Led.off();
        state = SHORT_OFF;
    }

    command void TestResultNotify.testFailed(uint8_t testNr) {
        if (state != IDLE) {
            return;
        }

        failNr = testNr;

        failPauseStart();
    }

    void failPauseStart() {
        call Timer.startWithTimeoutFromNow(2000);
        call Led.off();
        state = PAUSE_OFF;
    }

    void failNrCycleStart() {
        blinksLeft = failNr;
        failBlink();
    }

    void failBlink() {
        if (blinksLeft > 0) {
            blinksLeft -= 1;
            call Timer.startWithTimeoutFromNow(300);
            call Led.on();
            state = FSHORT_ON;
        }
        else {
            failPauseStart();
        }
    }

    void failOffAfterBlink() {
        call Timer.startWithTimeoutFromNow(300);
        call Led.off();
        state = FSHORT_OFF;
    }

    event void Timer.fired() {
        switch(state) {
            case LONG_BLINK:
                passShortOff();
                return;
            case SHORT_OFF:
                passLongOnStart();
                return;
            case PAUSE_OFF:
                failNrCycleStart();
                return;
            case FSHORT_ON:
                failOffAfterBlink();
                return;
            case FSHORT_OFF:
                failBlink();
                return;
        }
    }
}


/* Put the XML below in a file and open it with http://www.draw.io

<mxfile userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36" type="device"><diagram>5Vpbb+I4FP41SLsPrXIF+liY0hltt62WXe3u08glJkQ1MZuEXubXz3FyDrk4lBFNTTSLkEhObMf+zu3zMQN3un65Tthm9bsMuBg4VvAycD8NHMe2rCH8KMlrIRn7KAiTKMBGpWAefePUE6XbKOBprWEmpciiTV24kHHMF1lNtpSi/ooNC2n4UjBfMKFL/46CbIVTdnDKSv6ZR+GKXmMPL4onafZKYwR8ybYiO8tF8Ew9XjMaK1+VewWIJVLCMOpq/TLlQqFGgBRLn+15uptkwmOcyNsd3KLDExNbnGPKMxAIGYfwI2NtDc+rKOPzDVuo+2dQ7MCdrLK1gDsbLpeREFMpZJK3dmezmTOdghzfw5OMk/71ueYinOg1l2ueJa/QBDs4tl90QXNxxmgHz6U+bFyvtaroYogyhmYR7oYukYELBKcdKE8D6sunmysNnURu44CrPgqMA1h1gQmtFzGxvRZMyF+qmLgdYDLSls8D8Bm8lUm2kqGMmbgqpZMSIKsNDDXA21DA++Q2yREt1ZKxJAS7LU1aByzhgmXRU33096x+rFlExtMsvWdpyoNfftWwASXDDKtLTngafWMPeQOFBnyZiMIYbhewaA4+NFHWEUEUusQH6ygIciAFe+BiwhaPYQ5pxeeW+eegL2JUxPfvIsUhe8yVvtcerXPLtupuigHyh/HHse9lBK8sm8jlMg9NDQXtpvBDOsOQXNHZzd3t9dfJzZfb33rny25bfPsoX6ZxT+nMmIyqzpwrzIAz2ziGlgjTFSxdZULwqP6mQm9kMBXayFxOaSroyFVTKVRowlYQ+4qtLKPkZ475hcb3WuMZRH3XRe8lItKjqG/rLHf++e6PP7/ezWa9i/p+myt/WNTXae0+Uzbu4hSSaz5uitzZyFq6AQCWmbz+g/L85l91c+4fD05LrnwvNnnXyyRhqhc12CiHTFs8lOydMgqZ77iIjrsN54H2Lpp2qZdiBkf7Om5KKhY9cIZCReEgeoLLUF0WuX3DUmiDub1o85BQE5LACysde8QBPLfOAVq3fh/GAXD307e933s5wFE+4IwaO55uTZrm29hpzlgkIFLHyc9LO3Ije4t20Ca8G9JBM0HDqg/aLSPRN6L3l3/Nr3rBSJqBxTFZUyLTOCnzwBxSYx6mdqItdaV+7kGbZjIi1ZnIPy2VnMZ+vU+Va488g0iSyVRd5MRWRpRuGMBUwWj431adPExEFPMzmsglNLH9c9u+gM947Pv+hb15KRsTN1pCQroF/gQ+CENZsaJSRKGKN9WZVZVr9VZVRjWFhZWKphYrvnhUTcDzrQdQy2N6w5fKwAE7tla4IIKWkjRwrXU4K9RC8a4XYDuNMhaBbwRtvSpQBziHi4y6t5i5dG8EM313NetPKWXYqIqO2szpo4iLq+dtgub29JSOwhjtUHyTyOgH4eYpXUvBuAgABigdgf//KRgXKn9r5+Y1C8aY+3pRMPb0JGn+MKytwrenDt+9xeIW+KQAtNV/95w+dw8A1n8rLhtL9b+YnBucHBp0lk6hOar05dMZNTG4eu3rYHsbTzu6qpV5PfhPSpt2jB1kez0ozLadzhb0yAAAxGz6eKRFHLFmGcaA6UFSo+JWzTJMxXRf3173xzJaSo7vzvZHRfRh44DOw4h9ZISG2/LfrEXz8s/A7tV3</diagram></mxfile>

*/

