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
 * @author Szymon Acedanski
 * 
 * Implements support for standard interrupt: no hardware auto-clear,
 * clear flag before running the handler.
 */

generic module HplSimpleInterruptEventPrv() {
    provides interface ExternalEvent;
    uses interface InterruptSource;
}
implementation{
    async command void ExternalEvent.asyncNotifications(bool enable) {
        if (enable)
            call InterruptSource.enable();
        else
            call InterruptSource.disable();
    }

    async command void ExternalEvent.clearPending() {
        call InterruptSource.clearPending();
    }

    async event void InterruptSource.interruptFired() {
        signal ExternalEvent.triggered();
    }

    default async event void ExternalEvent.triggered() {}
}
