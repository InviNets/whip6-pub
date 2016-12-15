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
 * Overrides the Init.init() command for radio by initializing random seed based on radio noise
 * after radio initialization.
 */

#include "cipher_aes128.h"

module RandomInitAfterRadioInitPrv {
    provides interface Init;

    uses interface ParameterInit<uint16_t> as UnsecureSeedInit;
    uses interface ParameterInit<aes128_key_t *> as SecureSeedInit;
    uses interface Read<uint8_t> as RandomByte;
}

implementation {
    error_t initializeUnsecureSeed() {
        error_t error;
        uint8_t seedHigh, seedLow;
        
        error = call RandomByte.read(&seedHigh);
        if(error != SUCCESS) {
            return error;
        }
        error = call RandomByte.read(&seedLow);
        if(error != SUCCESS) {
            return error;;
        }

        return call UnsecureSeedInit.init(((uint16_t)seedHigh) << 8 | (uint16_t)seedLow);
    }

    error_t initializeSecureSeed() {
        aes128_key_t key;
        uint8_t i;

        for(i = 0; i < sizeof(key.key); ++i) {
            error_t error = call RandomByte.read(key.key + i);
            if(error != SUCCESS) {
                return error;
            }
        }

        return call SecureSeedInit.init(&key);
    }

    command error_t Init.init() {
        error_t error;

        /* Errors in initializing random seed are not reported to a user. */
        error = initializeUnsecureSeed();
        if(error != SUCCESS) {
            return SUCCESS;
        }
        error = initializeSecureSeed();
        return SUCCESS;
    }

    default command error_t UnsecureSeedInit.init(uint16_t seed) {
        return SUCCESS;
    }

    default command error_t SecureSeedInit.init(aes128_key_t *seed) {
        return SUCCESS;
    }
}
