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
 * Allows for calculating message authentication code based on CBC MAC with AES-128.
 */

#include "cipher_aes128.h"
#include "SleepLevels.h"

generic module AuthenticateAES128Prv() {
    provides interface AuthenticateAES<aes128_key_t, aes128_mac_t>;

    uses interface AskBeforeSleep;
    uses interface Resource;
}

implementation {
    /* Setting initialization vector (nonce) to zeros is required when calculating a tag. */
    const aes128_nonce_t NONCE_ZEROS = {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};

    bool m_res_waiting = FALSE;
    bool m_busy = FALSE;

    uint32_t m_current_block;
    aes128_key_t *m_key;
    uint8_t_xdata *m_input;
    uint32_t m_length;
    aes128_mac_t *m_mac;

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return m_busy? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }

    command error_t AuthenticateAES.calculateMac(aes128_key_t *key, uint8_t_xdata *input, uint32_t length,
            aes128_mac_t *mac) {
        error_t error;

        if(m_busy || m_res_waiting) {
            return EBUSY;
        }
        if(length % AES128_BLOCK_SIZE_BYTES != 0) {
            return ESIZE;
        }
        if(key == NULL || input == NULL || mac == NULL) {
            return EINVAL;
        }

        error = call Resource.request();
        if(error == SUCCESS) {
            m_res_waiting = TRUE;
            m_key = key;
            m_input = input;
            m_length = length;
            m_mac = mac;
        }
        return error;
    }

    void finishCalculating(error_t error) {
        m_busy = FALSE;
        signal AuthenticateAES.calculateMacDone(error, m_key, m_input, m_length, m_mac);
    }

    event void Resource.granted() {
        // TODO(accek)
        m_busy = TRUE;
        finishCalculating(ENOSYS);
    }

    default event void AuthenticateAES.calculateMacDone(error_t error, aes128_key_t *key, uint8_t_xdata *input,
            uint32_t length, aes128_mac_t *mac) {}
}
