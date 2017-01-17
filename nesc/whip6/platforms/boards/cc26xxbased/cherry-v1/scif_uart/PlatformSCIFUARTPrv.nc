/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 *
 */
#include "scif_uart_emulator.h"

module PlatformSCIFUARTPrv {
    provides interface OnOffSwitch;
    uses interface SCIF;
}
implementation {
    command error_t OnOffSwitch.on() {
        error_t err = call SCIF.scifInit();
        if (err != SUCCESS) {
            return err;
        }

        if (scifExecuteTasksOnceNbl(1 << SCIF_UART_EMULATOR_TASK_ID)
                != SCIF_SUCCESS) {
            call OnOffSwitch.off();
            return EINTERNAL;
        }

        return err;
    }

    command error_t OnOffSwitch.off() {
        call SCIF.scifUninit();
        return SUCCESS;
    }

    event const SCIF_DATA_T* SCIF.scifGetDriver() {
        return &scifDriverSetup;
    }

    async event void SCIF.scifReadyInt() {
        // do nothing
    }

    async event void SCIF.scifAlertInt() {
        panic("Spurious alert from Sensor Controller");
    }
}
