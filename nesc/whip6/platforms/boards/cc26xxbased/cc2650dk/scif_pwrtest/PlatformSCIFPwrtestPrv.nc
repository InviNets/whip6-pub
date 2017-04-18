/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "scif_pwrtest.h"

module PlatformSCIFPwrtestPrv {
    provides interface OnOffSwitch;
    uses interface SCIF;
}
implementation {
    command error_t OnOffSwitch.on() {
        error_t err = call SCIF.scifInit();
        if (err != SUCCESS) {
            return err;
        }

        // 1 Hz
        scifPwrtestStartRtcTicksNow(1 << 15);

        if (scifStartTasksNbl(1 << SCIF_PWRTEST_POWER_CONSUMPTION_TEST_TASK_ID)
                != SCIF_SUCCESS) {
            call OnOffSwitch.off();
            return EINTERNAL;
        }

        return err;
    }

    command error_t OnOffSwitch.off() {
        scifPwrtestStopRtcTicks();
        call SCIF.scifUninit();
        return SUCCESS;
    }

    event const SCIF_DATA_T* SCIF.scifGetDriver() {
        return &scifPwrtestDriverSetup;
    }

    async event void SCIF.scifReadyInt() {
        // do nothing
    }

    async event void SCIF.scifAlertInt() {
        panic("Spurious alert from Sensor Controller");
    }
}
