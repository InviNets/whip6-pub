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
 * Interface definition for modules providing AES message authentication codes functionality.
 *
 * @param aes_key_t type of keys
 * @param aes_mac_t type of message authentication codes
 */
interface AuthenticateAES<aes_key_t, aes_mac_t> {
    /**
     * Calculates message authentication code of the input buffer and stores it in the mac parameter. The length of the
     * input buffer must be multiple of block size (AES128_BLOCK_SIZE_BYTES).
     *
     * @return SUCCESS if calculateMacDone will eventually be called, error code otherwise
     */
    command error_t calculateMac(aes_key_t *key, uint8_t_xdata *data, uint32_t length, aes_mac_t *mac);

    /**
     * Signals that calculating message authentication code has finished.
     */
    event void calculateMacDone(error_t error, aes_key_t *key, uint8_t_xdata *data, uint32_t length, aes_mac_t *mac);
}
