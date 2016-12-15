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
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Shared counter of a fixed length passed as a parameter.
 */
generic module SharedCounterPub(uint16_t lengthBytes) {
    provides interface SharedCounter;
}

implementation {
    uint8_t m_counter[lengthBytes];

    command uint8_t *SharedCounter.getValue() {
        return m_counter;
    }

    command uint16_t SharedCounter.getLengthBytes() {
        return lengthBytes;
    }

    command void SharedCounter.zero() {
        uint16_t i;
        for(i = 0; i < sizeof(m_counter); ++i) {
            m_counter[i] = 0;
        }
    }

    command void SharedCounter.increment() {
        uint16_t i;
        bool overflow = TRUE;
        for(i = 0; i < sizeof(m_counter) && overflow; ++i) {
            uint16_t pos = sizeof(m_counter) - 1 - i;
            overflow = m_counter[pos] == 0xff;
            ++m_counter[pos];
        }
        if(overflow) {
            signal SharedCounter.overflow();
        }
    }

    default event void SharedCounter.overflow() {}
}
