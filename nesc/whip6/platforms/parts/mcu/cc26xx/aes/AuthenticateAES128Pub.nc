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
 * Allows for calculating message authentication code based on CBC MAC with AES-128.
 */

#include "cipher_aes128.h"

generic configuration AuthenticateAES128Pub() {
    provides interface AuthenticateAES<aes128_key_t, aes128_mac_t>;
}

implementation {
    components new AuthenticateAES128Prv() as Authenticate;
    AuthenticateAES = Authenticate;

    components new HalAskBeforeSleepPub();
    Authenticate.AskBeforeSleep -> HalAskBeforeSleepPub;

    components new HalAESResourcePub() as Resource;
    Authenticate.Resource -> Resource;
}
