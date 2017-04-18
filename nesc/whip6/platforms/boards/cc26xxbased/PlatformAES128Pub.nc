/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 *
 * Allows for encrypting and decrypting data with AES-128 (CBC mode) as
 * well as MAC authentication.
 */

#include "cipher_aes128.h"

generic configuration PlatformAES128Pub() {
    provides interface CipherAES<aes128_key_t, aes128_nonce_t> as Encrypt;
    provides interface CipherAES<aes128_key_t, aes128_nonce_t> as Decrypt;
    provides interface AuthenticateAES<aes128_key_t, aes128_mac_t> as Authenticate;
}

implementation {
    // TODO(accek): zmodyfikowac jak bedzie implementacja

    components new CipherAES128CryptPub() as EncryptPub;
    Encrypt = EncryptPub;

    components new CipherAES128CryptPub() as DecryptPub;
    Decrypt = DecryptPub;

    components new AuthenticateAES128Pub() as AuthenticatePub;
    Authenticate = AuthenticatePub;
}
