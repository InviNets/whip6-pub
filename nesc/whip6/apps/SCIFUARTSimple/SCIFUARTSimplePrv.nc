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
    uint32_t DATA_TO_SEND = 5; // MB = 10^6 bytes
    uint32_t BAUD_RATE = 230400;

    uint32_t bytes_to_send;
    char test_msg[] = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ";
    uint32_t size;

    event void Boot.booted() {
        size = strlen(test_msg);
        // -1 because of the final newline
        bytes_to_send = DATA_TO_SEND * 1000000 - 1;
        call SCOnOff.on();
        call Timer.startWithTimeoutFromNow(2048); // ms
    }

    event void Timer.fired() {
        int i = 0, j;
        scifUartSetBaudRate(BAUD_RATE);

        while (bytes_to_send) {
            while (scifUartGetTxFifoCount() >= SCIF_UART_TX_FIFO_MAX_COUNT);
            scifUartTxPutChar((i % 10) + (int) '0');

            bytes_to_send--;
            if (!bytes_to_send) break;

            for (j = 0; j < size; j++) {
                while (scifUartGetTxFifoCount() >= SCIF_UART_TX_FIFO_MAX_COUNT);
                scifUartTxPutChar(test_msg[j]);

                bytes_to_send--;
                if (!bytes_to_send) break;
            }

            if (!bytes_to_send) break;

            while (scifUartGetTxFifoCount() + 1 >= SCIF_UART_TX_FIFO_MAX_COUNT);
            scifUartTxPutChar((i % 32) + (int) '!');

            bytes_to_send--;
            if (!bytes_to_send) break;

            scifUartTxPutChar('\n');

            bytes_to_send--;
            i++;
        }

        while (scifUartGetTxFifoCount() >= SCIF_UART_TX_FIFO_MAX_COUNT);
        scifUartTxPutChar('\n');
    }
}
