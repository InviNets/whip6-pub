/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

generic module DummyBeeperPub() {
    provides interface Beeper;
}
implementation {
    command error_t Beeper.beep(uint8_t numBeeps) {
        return SUCCESS;
    }

    command error_t Beeper.beepSequence(const char_code* sequence) {
        return SUCCESS;
    }
}
