/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Allows for encrypting or decrypting (depending on a CryptWrite module wired to this module)
 * data with AES-128.
 */

#include "cipher_aes128.h"
#include "SleepLevels.h"

generic module CipherAES128CryptPrv() {
    provides interface CipherAES<aes128_key_t, aes128_nonce_t>;

    uses interface AskBeforeSleep;
    uses interface Resource;
}

implementation {
    bool m_res_waiting = FALSE;
    bool m_busy = FALSE;

    uint32_t m_current_chunk;
    aes128_key_t *m_key;
    aes128_nonce_t *m_nonce;
    uint8_t_xdata *m_data;
    uint32_t m_length;

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return m_busy? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }

    void finishCrypt(error_t error) {
        m_busy = FALSE;
        call Resource.release();
        signal CipherAES.cryptMessageDone(error, m_key, m_nonce, m_data, m_length);
    }

    event void Resource.granted() {
        // TODO(accek)
        m_busy = TRUE;
        finishCrypt(ENOSYS);
    }

    command error_t CipherAES.cryptMessage(aes128_key_t *key, aes128_nonce_t *nonce,
            uint8_t_xdata *data, uint32_t length) {
        error_t error;

        if(m_busy || m_res_waiting) {
            return EBUSY;
        }
        if(length % AES128_BLOCK_SIZE_BYTES != 0) {
            return ESIZE;
        }
        if(key == NULL || nonce == NULL || data == NULL) {
            return EINVAL;
        }

        error = call Resource.request();
        if(error == SUCCESS) {
            m_res_waiting = TRUE;
            m_key = key;
            m_nonce = nonce;
            m_data = data;
            m_length = length;
        }
        return error;
    }

    default event void CipherAES.cryptMessageDone(error_t error, aes128_key_t *key, aes128_nonce_t *nonce,
            uint8_t_xdata *data, uint32_t length) {}
}
