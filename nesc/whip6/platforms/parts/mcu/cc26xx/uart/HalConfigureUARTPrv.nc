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
 * @author Szymon Acedanski
 * 
 * Component responsible for configuring the UART.
 *
 * See HalConfigureUART.h for baud rate configuration.
 */

#include "hw_memmap.h"
#include "sys_ctrl.h"
#include "prcm.h"
#include "uart.h"
#include "ioc.h"

generic module HalConfigureUARTPrv(uint32_t uartBase, uint32_t baud, bool enableFIFO) {
    provides interface Init @exactlyonce();
    provides interface Init as ReInitRegisters @exactlyonce();

    uses interface CC26xxPin as RXPin @atmostonce();
    uses interface CC26xxPin as TXPin @atmostonce();
    uses interface ExternalEvent as Interrupt @exactlyonce();
    uses interface ShareableOnOff as PowerDomain @exactlyonce();
}
implementation {
    command error_t Init.init() {
        call PowerDomain.on();

        PRCMPeripheralRunEnable(uartBase == UART0_BASE ?
                PRCM_PERIPH_UART0 : PRCM_PERIPH_UART1);
        PRCMPeripheralSleepEnable(uartBase == UART0_BASE ?
                PRCM_PERIPH_UART0 : PRCM_PERIPH_UART1);
        PRCMPeripheralDeepSleepEnable(uartBase == UART0_BASE ?
                PRCM_PERIPH_UART0 : PRCM_PERIPH_UART1);
        PRCMLoadSet();
        while (!PRCMLoadGet()) /* nop */;

        UARTDisable(uartBase);
        return call ReInitRegisters.init();
    }

    command error_t ReInitRegisters.init() {
        UARTConfigSetExpClk(uartBase, SysCtrlClockGet(), baud,
                UART_CONFIG_WLEN_8 | UART_CONFIG_PAR_NONE | UART_CONFIG_STOP_ONE);
        UARTEnable(uartBase);
        if (enableFIFO) {
            UARTFIFOEnable(uartBase);
        } else {
            UARTFIFODisable(uartBase);
        }
        call Interrupt.clearPending();
        call Interrupt.asyncNotifications(TRUE);
        return SUCCESS;
    }

    event void RXPin.configure() {
        IOCPinTypeUart(uartBase, call RXPin.IOId(), IOID_UNUSED, IOID_UNUSED,
                IOID_UNUSED);
    }

    event void TXPin.configure() {
        IOCPinTypeUart(uartBase, IOID_UNUSED, call TXPin.IOId(), IOID_UNUSED,
                IOID_UNUSED);
    }

    async event void Interrupt.triggered() {}
}
