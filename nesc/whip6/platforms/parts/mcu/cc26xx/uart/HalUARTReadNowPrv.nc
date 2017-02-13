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
 * Handles bytes incoming from UART. Presents a ReadNow interface.
 */

#include "uart.h"
#include "Assert.h"
#include "SleepLevels.h"

generic module HalUARTReadNowPrv(uint32_t uartBase) {
    provides interface ReadNow<uint8_t>;

    uses interface ExternalEvent as Interrupt @exactlyonce();
    uses interface AskBeforeSleep @exactlyonce();
}

implementation {
    volatile bool busy = FALSE;

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        atomic {
            return busy ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
        }
    }

    async command error_t ReadNow.read() {
        atomic {
            if(busy) {
                return EBUSY;
            }
            busy = TRUE;
        }

        UARTIntClear(uartBase, UART_INT_RX);
        UARTIntEnable(uartBase, UART_INT_RX);
        return SUCCESS;
    }

    async event void Interrupt.triggered() {
        int32_t value;

        if (UARTIntStatus(uartBase, true) & UART_INT_RX) {
            UARTIntClear(uartBase, UART_INT_RX);
            UARTIntDisable(uartBase, UART_INT_RX);
            value = UARTCharGetNonBlocking(uartBase);
            CHECK(value != -1);
            atomic busy = FALSE;
            signal ReadNow.readDone(SUCCESS, (uint8_t)value);
        }
    }

    default async event void ReadNow.readDone(error_t result, uint8_t val) { }
}
