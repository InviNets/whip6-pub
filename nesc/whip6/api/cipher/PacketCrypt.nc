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
 * Interface that allows for encrypting and signing packets of fixed size with a block cipher.
 */

interface PacketCrypt<key_t, packet_t> {
    command error_t encrypt(key_t *key, packet_t *packet);

    /* Provides a pointer to encrypted data and their length (may be different from the length of the original packet).
     * Layout of data depends on the cipher. The data buffer may be used until the next call to the API.
     */
    event void encryptDone(key_t *key, packet_t *packet, uint8_t_xdata *data, uint16_t length, error_t error);

    command error_t sign(key_t *key, packet_t *packet);

    /* Provides a pointer to signed data and their length (may be different from the length of the original packet).
     * Layout of data depends on the cipher. The data buffer may be used until the next call to the API.
     */
    event void signDone(key_t *key, packet_t *packet, uint8_t_xdata *data, uint16_t length, error_t error);

    command error_t signAndEncrypt(key_t *signKey, key_t *encryptKey, packet_t *packet);

    /* Provides a pointer to signed and encrypted data and their length (may be different from the length of the
     * original packet). Layout of data depends on the cipher. The data buffer may be used until the next to the API.
     */
    event void signAndEncryptDone(key_t *signKey, key_t *encryptKey, packet_t *packet, uint8_t_xdata *data,
            uint16_t length, error_t error);
}
