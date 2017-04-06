/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 *
 */

#include "GlobalPutchar.h"

module NonBlockingWritePutcharProviderPub {
    uses interface NonBlockingWrite<uint8_t>;
} implementation {
    void whip6_putchar(char byte) __attribute__ ((spontaneous)) @C() {
        call NonBlockingWrite.write(byte);
    }
}
