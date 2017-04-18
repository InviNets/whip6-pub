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

generic module HalUARTBlockingWritePrv(uint32_t uartBase) {
    provides interface BlockingWrite<uint8_t>;

    uses interface ExternalEvent as Interrupt @exactlyonce();
    uses interface AskBeforeSleep @exactlyonce();
}

implementation {
    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        atomic {
            return UARTBusy(uartBase) ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
        }
    }

    async command error_t BlockingWrite.write(uint8_t value) {
        /* We need the interrupt configured, even if we do not seem to use it.
         * It's needed so that the CPU is woken up when in IDLE sleep, so that
         * we can switch to DEEP sleep.
         *
         * Also note that the hardware does not provide the TX complete
         * interrupt when running in FIFO mode, therefore we don't use
         * FIFO. */
        call BlockingWrite.waitForEndOfTransmission();
        UARTIntClear(uartBase, UART_INT_TX);
        UARTIntEnable(uartBase, UART_INT_TX);
        UARTCharPut(uartBase, value);
        return SUCCESS;
    }

    async command error_t BlockingWrite.waitForEndOfTransmission() {
        while (UARTBusy(uartBase)) /* nop */;
        return SUCCESS;
    }

    async event void Interrupt.triggered() {
        if (UARTIntStatus(uartBase, true) & UART_INT_TX) {
            UARTIntClear(uartBase, UART_INT_TX);
            UARTIntDisable(uartBase, UART_INT_TX);
        }
    }
}
