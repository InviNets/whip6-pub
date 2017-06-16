/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Przemyslaw <extremegf@gmail.com>
 * @author Szymon Acedanski
 *
 * Supports IO Pin interrupts.
 */

#include "ioc.h"

module HalGPIOInterruptsPrv {
    provides interface ExternalEvent[uint32_t IOId];
    provides interface GPIOEventConfig[uint32_t IOId];

    uses {
        interface InterruptSource as GPIOInterrupt;
        interface CC26xxWakeUpSource as WakeUpSource;
    }
}
implementation {
    uint32_t enabledNotificationsMask;

    command void GPIOEventConfig.triggerOnRisingEdge[uint32_t IOId]() {
        IOCIOIntSet(IOId, IOC_INT_ENABLE, IOC_RISING_EDGE);
    }

    command void GPIOEventConfig.triggerOnFallingEdge[uint32_t IOId]() {
        IOCIOIntSet(IOId, IOC_INT_ENABLE, IOC_FALLING_EDGE);
    }

    command void GPIOEventConfig.triggerOnBothEdges[uint32_t IOId]() {
        IOCIOIntSet(IOId, IOC_INT_ENABLE, IOC_BOTH_EDGES);
    }

    command void GPIOEventConfig.setupExternalEvent[uint32_t IOId]() {
        atomic {
            call ExternalEvent.asyncNotifications[IOId](FALSE);
            call ExternalEvent.clearPending[IOId]();
            call GPIOInterrupt.clearPending();
            call GPIOInterrupt.enable();
            call WakeUpSource.enableWakeUp();
        }
    }

    async command void ExternalEvent.asyncNotifications[uint32_t IOId](bool enable) {
        atomic {
            if (enable) {
                enabledNotificationsMask |= (1UL << IOId);
                IOCIntEnable(IOId);
            } else {
                enabledNotificationsMask &= ~(1UL << IOId);
                IOCIntDisable(IOId);
            }
        }
    }

    async event void GPIOInterrupt.interruptFired() {
        // We record the current state of the flag locally.
        // Then we set the flag to the negation of the record.
        // 0 bits will be cleared. 1 bits will remain untouched.
        // This way, if an event is triggered in middle of a write cycle
        // it will not be lost.
        //
        // Only event that might be lost is the one that will be reasserted
        // just before the 0 is written, but its handler will run in a moment
        // anyway.
        //
        // To sum up, in a super-fast series of events, we will only handle
        // the first one and ignore following ones.

        uint32_t flagSnapshot;
        uint8_t IOId;

        atomic {
            flagSnapshot = GPIO_getEventMultiDio(enabledNotificationsMask);
            GPIO_clearEventMultiDio(flagSnapshot);
        }

        IOId = 0;
        while(flagSnapshot) {
            if(flagSnapshot & 1) {
                signal ExternalEvent.triggered[IOId]();
            }
            flagSnapshot >>= 1;
            IOId++;
        }
    }

    async command void ExternalEvent.clearPending[uint32_t IOId]() {
        atomic {
            GPIO_clearEventDio(IOId);
        }
    }

    default async event void ExternalEvent.triggered[uint32_t IOId]() {}
}
