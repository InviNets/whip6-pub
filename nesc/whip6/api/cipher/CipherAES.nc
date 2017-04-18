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
 * Interface definition for modules providing AES functionality.
 *
 * @param aes_key_t type of keys
 * @param aes_nonce_t type of nonce values (initialization vectors)
 */
interface CipherAES<aes_key_t, aes_nonce_t> {
    /**
     * Encrypts or decrypts (depending on a module providing this command) the input buffer. The length must be multiple
     * of the block size (AES128_BLOCK_SIZE_BYTES). The output data is written to the same buffer.
     *
     * @return SUCCESS if cryptMessageDone will eventually be called, error code otherwise
     */
    command error_t cryptMessage(aes_key_t *key, aes_nonce_t *nonce, uint8_t_xdata *data, uint32_t length);

    /**
     * Signals that encryption or decryption has finished.
     */
    event void cryptMessageDone(error_t error, aes_key_t *key, aes_nonce_t *nonce, uint8_t_xdata *data,
            uint32_t length);
}
