/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
#include "scif_uart_emulator.h"

generic module HalConfigureSCUARTPrv(uint32_t baud) {
    provides interface Init @exactlyonce();

    uses interface OnOffSwitch as SCOnOff;
} implementation {
    command error_t Init.init() {
        call SCOnOff.on();
        scifUartSetBaudRate(baud);
        return SUCCESS;
    }
}
