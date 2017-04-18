/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "scif_framework.h"

module HalSCIFPrv {
    provides interface SCIF @exactlyonce();

    uses interface ExternalEvent as ReadyEvent;
    uses interface ExternalEvent as AlertEvent;
    uses interface CC26xxWakeUpSource as SW0WakeUpSource;
    uses interface CC26xxWakeUpSource as SW1WakeUpSource;
}
implementation {
    command error_t SCIF.scifInit() {
        SCIF_RESULT_T result = scifInit(signal SCIF.scifGetDriver());
        switch (result) {
            case SCIF_NOT_READY:
                return EBUSY;
            case SCIF_ILLEGAL_OPERATION:
                return EINVAL;
            case SCIF_SUCCESS:
                // do nothing
        }
        call SW0WakeUpSource.enableWakeUp();
        call SW1WakeUpSource.enableWakeUp();
        return SUCCESS;
    }

    command void SCIF.scifUninit() {
        call SW0WakeUpSource.disableWakeUp();
        call SW1WakeUpSource.disableWakeUp();
        scifUninit();
    }

    inline async event void ReadyEvent.triggered() {
        scifClearReadyIntSource();
        call ReadyEvent.asyncNotifications(FALSE);
        signal SCIF.scifReadyInt();
    }

    inline async event void AlertEvent.triggered() {
        scifClearAlertIntSource();
        call AlertEvent.asyncNotifications(FALSE);
        signal SCIF.scifAlertInt();
    }

    void osalClearCtrlReadyInt(void) @C() @spontaneous() {
        call ReadyEvent.clearPending();
    }

    void osalEnableCtrlReadyInt(void) @C() @spontaneous() {
        call ReadyEvent.asyncNotifications(TRUE);
    }

    void osalDisableCtrlReadyInt(void) @C() @spontaneous() {
        call ReadyEvent.asyncNotifications(FALSE);
    }

    void osalClearTaskAlertInt(void) @C() @spontaneous() {
        call AlertEvent.clearPending();
    }

    void osalEnableTaskAlertInt(void) @C() @spontaneous() {
        call AlertEvent.asyncNotifications(TRUE);
    }

    void osalDisableTaskAlertInt(void) @C() @spontaneous() {
        call AlertEvent.asyncNotifications(FALSE);
    }

    default async event void SCIF.scifReadyInt() {
        // do nothing
    }

    default async event void SCIF.scifAlertInt() {
        panic("Spurious alert from Sensor Controller");
    }
}
