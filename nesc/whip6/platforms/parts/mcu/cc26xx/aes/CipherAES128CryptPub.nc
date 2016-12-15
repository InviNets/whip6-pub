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
 * Allows for encrypting or decrypting (depending on a CryptWrite module wired to this module)
 * data with AES-128.
 */

#include "cipher_aes128.h"

generic configuration CipherAES128CryptPub() {
    provides interface CipherAES<aes128_key_t, aes128_nonce_t> as Crypt;
}

implementation {
    components new CipherAES128CryptPrv() as CipherAES;
    Crypt = CipherAES;

    components new HalAskBeforeSleepPub();
    CipherAES.AskBeforeSleep -> HalAskBeforeSleepPub;

    components new HalAESResourcePub() as Resource;
    CipherAES.Resource -> Resource;
}
