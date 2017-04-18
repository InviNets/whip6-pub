/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

#include "uart.h"

generic module HalUARTBlockingReadPrv(uint32_t uartBase) {
    provides interface BlockingRead<uint8_t>;
}

implementation {
    async command uint8_t BlockingRead.read() {
        return UARTCharGet(uartBase);
    }

    async command void BlockingRead.flushBuffers() {
        while (UARTBusy(uartBase)) /* nop */;
    }
}
