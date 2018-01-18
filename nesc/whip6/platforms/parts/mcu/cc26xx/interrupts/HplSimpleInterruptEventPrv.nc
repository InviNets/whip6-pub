/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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

    async command bool ExternalEvent.getPending() {
        return call InterruptSource.getPending();
    }

    async event void InterruptSource.interruptFired() {
        signal ExternalEvent.triggered();
    }

    default async event void ExternalEvent.triggered() {}
}
