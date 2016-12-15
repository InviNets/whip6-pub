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
 * Random number generator derived from the AES cipher. Generation of random values is as follows:
 * 1. One must provide a seed which is AES key.
 * 2. The generator encrypts blocks containing subsequent integers (0, 1, 2, ..., 2 ^ blockSize - 1)
 *    with the provided key and nonce set to 0. These blocks are the output. Therefore, the period
 *    (in bytes) is blockSize * 2 ^ blockSize.
 *
 * Calling ParameterInit.init(aes_key_t) is obligatory (otherwise, the command that generates random
 * values will return EOFF). Initializing more than once will not reset the counter to prevent from
 * security issues when a user reinitializes the generator with the same key. For that purpose, the
 * same SharedCounter should be wired to every instance of this module, because otherwise, different
 * instances initialized with the same key would return the same values.
 */

#include "cipher_aes128.h"

generic module RandomAESPub(typedef aes_key_t, typedef aes_nonce_t, uint8_t blockSize) {
    provides interface AsyncRandom;
    provides interface ParameterInit<aes_key_t *>;

    uses interface CipherAES<aes_key_t, aes_nonce_t> as EncryptAES;
    uses interface SharedCounter;
}

implementation {
    bool m_initialized = FALSE;
    aes_key_t m_key;
    aes_nonce_t m_emptyNonce;

    bool m_busy = FALSE;
    uint8_t_xdata *m_buffer;
    uint16_t m_length;
    uint16_t m_lengthLeft;

    uint8_t_xdata m_cache[blockSize];
    uint8_t m_cachePos = blockSize;

    task void generateNextBlockTask();

    command error_t AsyncRandom.generateRandom(uint8_t_xdata *buffer, uint16_t length) {
        if(!m_initialized) {
            return EOFF;
        }
        if(m_busy) {
            return EBUSY;
        }
        if(buffer == NULL) {
            return EINVAL;
        }

        m_buffer = buffer;
        m_length = m_lengthLeft = length;
        m_busy = TRUE;
        post generateNextBlockTask();
        return SUCCESS;
    }

    void finishGenerating(error_t error) {
        m_busy = FALSE;
        signal AsyncRandom.generateRandomDone(error, m_buffer, m_length);
    }

    uint16_t minUint16(uint16_t a, uint16_t b) {
        return a < b? a : b;
    }

    void generateNextBlock() {
        uint16_t copiedNow;

        copiedNow = minUint16(sizeof(m_cache) - m_cachePos, m_length);
        memcpy(m_buffer, m_cache + m_cachePos, copiedNow);
        m_lengthLeft -= copiedNow;
        m_cachePos += copiedNow;

        if(m_lengthLeft == 0) {
            finishGenerating(SUCCESS);
        } else {
            error_t error;
            memcpy(m_cache, call SharedCounter.getValue(), sizeof(m_cache));
            error = call EncryptAES.cryptMessage(&m_key, &m_emptyNonce, (uint8_t_xdata *)m_cache, sizeof(m_cache));
            if(error != SUCCESS) {
                finishGenerating(error);
            }
        }
    }

    task void generateNextBlockTask() {
        generateNextBlock();
    }

    event void EncryptAES.cryptMessageDone(error_t error, aes_key_t *key, aes_nonce_t *nonce, uint8_t_xdata *data,
            uint32_t length) {
        call SharedCounter.increment();
        m_cachePos = 0;
        if(error == SUCCESS) {
            generateNextBlock();
        } else {
            finishGenerating(error);
        }
    }

    command error_t ParameterInit.init(aes_key_t *seed) {
        if(seed == NULL) {
            return EINVAL;
        }
        if(call SharedCounter.getLengthBytes() != blockSize || AES128_BLOCK_SIZE_BYTES != blockSize) {
            /* This should be a compilation error, because it means that someone wired a wrong module,
             * but achieving this would be quite complicated. */
            return EINVAL;
        }
        memcpy(&m_key, seed, sizeof(m_key));
        if(!m_initialized) {
            /* For better security, we zero the counter only during the first initialization.
             * Therefore, if a user initalizes the generator second time with the same seed,
             * the sequence will not reset. */
            memset(&m_emptyNonce, 0, sizeof(m_emptyNonce));
            call SharedCounter.zero();
            m_initialized = TRUE;
        }
        return SUCCESS;
    }

    event void SharedCounter.overflow() {}

    default event void AsyncRandom.generateRandomDone(error_t error, uint8_t *buffer, uint16_t length) {}
}
