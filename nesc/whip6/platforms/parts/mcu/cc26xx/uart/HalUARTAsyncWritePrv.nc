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
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 * 
 * Asynchronously writes bytes to the UART
 */

#include <stdbool.h>
#include "SleepLevels.h"

generic module HalUARTAsyncWritePrv(uint32_t uartBase) {
    provides interface AsyncWrite<uint8_t>;

    uses interface ExternalEvent as Interrupt;
    uses interface AskBeforeSleep;
}

implementation {
    volatile bool busy = FALSE;

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        atomic {
            return busy ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
        }
    }

    async command error_t AsyncWrite.startWrite(uint8_t value) {
        bool ok;

        atomic {
            if(busy) {
                return EBUSY;
            }
            busy = TRUE;
        }

        UARTIntClear(uartBase, UART_INT_TX);
        UARTIntEnable(uartBase, UART_INT_TX);
        ok = UARTCharPutNonBlocking(uartBase, value);
        CHECK(ok);

        (void)ok;

        return SUCCESS;
    }

    async event void Interrupt.triggered() {
        if (UARTIntStatus(uartBase, true) & UART_INT_TX) {
            UARTIntClear(uartBase, UART_INT_TX);
            UARTIntDisable(uartBase, UART_INT_TX);
            atomic busy = FALSE;
            signal AsyncWrite.writeDone(SUCCESS);
        }
    }
}
