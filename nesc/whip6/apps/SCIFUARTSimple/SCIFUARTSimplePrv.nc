/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include <string.h>
#include "scif_uart_emulator.h"


module SCIFUARTSimplePrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t>;
    uses interface OnOffSwitch as SCOnOff;
}

implementation {
    uint32_t NUM_OF_LINES = 100000;
    uint32_t BAUD_RATE = 115200;

    char test_msg[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ";
    uint32_t size;

    event void Boot.booted() {
        size = strlen(test_msg);
        call SCOnOff.on();
        call Timer.startWithTimeoutFromNow(2048); // ms
    }

    event void Timer.fired() {
        int i, j;
        scifUartSetBaudRate(BAUD_RATE);

        for (i = 0; i < NUM_OF_LINES; i++) {
            for (j = 0; j < size; j++) {
                while (scifUartGetTxFifoCount() >= SCIF_UART_TX_FIFO_MAX_COUNT);
                scifUartTxPutChar(test_msg[j]);
            }

            while (scifUartGetTxFifoCount() + 1 >= SCIF_UART_TX_FIFO_MAX_COUNT);
            scifUartTxPutChar((i % 32) + (int) '!');
            scifUartTxPutChar('\n');

        }
    }
}
