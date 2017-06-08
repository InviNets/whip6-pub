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
 * uDMA controller on CC2538.
 *
 * Well, there's a bit complex logic regarding the sleep mode
 * handling:
 *
 * The controller assumes that the channel is active from when
 * DMAChannel.enable() is called until someone calls
 * DMAChannel.intStatus() and it returns true, or until
 * someone explicitly calls DMAChannel.disable().
 *
 * @author Szymon Acedanski
 */

#include <driverlib/udma.h>
#include "SleepLevels.h"

module HalDMAPrv {
    provides interface DMAChannel[uint8_t channel];
    provides interface OnOffSwitch @exactlyonce();

    uses interface AskBeforeSleep @exactlyonce();
    uses interface ExternalEvent as DMASwInt @exactlyonce();
    uses interface ExternalEvent as DMAErrInt @exactlyonce();
}

implementation {
    /* .bigalignbss makes the table appear at the beginning of memory, so we
     * won't waste space for aligment */
    uint8_t uDMAControlTable[512]
        __attribute__((section(".bigalignbss"), aligned(1024)));

    bool channelActive[UDMA_NUM_CHANNELS];
    uint8_t numActiveChannels = 0;
    bool isOn = FALSE;

    command error_t OnOffSwitch.on() {
        PRCMPeripheralRunEnable(PRCM_PERIPH_UDMA);
        PRCMPeripheralSleepEnable(PRCM_PERIPH_UDMA);
        PRCMPeripheralDeepSleepEnable(PRCM_PERIPH_UDMA);

        PRCMLoadSet();
        while(!PRCMLoadGet()) /* nop */;

        uDMAEnable(UDMA0_BASE);
        uDMAControlBaseSet(UDMA0_BASE, uDMAControlTable);
        call DMASwInt.asyncNotifications(TRUE);
        call DMAErrInt.asyncNotifications(TRUE);

        isOn = TRUE;

        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        if (!isOn) {
            return EALREADY;
        }
        if (numActiveChannels) {
            panic();
        }

        call DMASwInt.asyncNotifications(FALSE);
        call DMAErrInt.asyncNotifications(FALSE);

        uDMADisable(UDMA0_BASE);

        PRCMPeripheralRunDisable(PRCM_PERIPH_UDMA);
        PRCMPeripheralSleepDisable(PRCM_PERIPH_UDMA);
        PRCMPeripheralDeepSleepDisable(PRCM_PERIPH_UDMA);
        PRCMLoadSet();

        isOn = FALSE;

        return SUCCESS;
    }

    static inline void mustBeOn() {
        if (!isOn) {
            panic("Accessing DMA without powering it on");
        }
    }

    inline void setChannelActive(uint8_t channel) {
        atomic {
            if (!channelActive[channel]) {
                channelActive[channel] = TRUE;
                numActiveChannels++;
            }
        }
    }

    inline void setChannelInactive(uint8_t channel) {
        atomic {
            if (channelActive[channel]) {
                channelActive[channel] = FALSE;
                numActiveChannels--;
            }
        }
    }

    event sleep_level_t AskBeforeSleep.maxSleepLevel() {
        uint8_t count;
        atomic count = numActiveChannels;
        return count > 0 ? SLEEP_LEVEL_IDLE : SLEEP_LEVEL_DEEP;
    }

    async command bool DMAChannel.intStatus[uint8_t channel]() {
        bool status;
        mustBeOn();
        status = !!(uDMAIntStatus(UDMA0_BASE) & (1UL << channel));
        if (status) {
            setChannelInactive(channel);
        }
        return status;
    }

    async command void DMAChannel.clearInt[uint8_t channel]() {
        mustBeOn();
        uDMAIntClear(UDMA0_BASE, 1UL << channel);
    }

    command void DMAChannel.controlSet[uint8_t channel](uint32_t control) {
        mustBeOn();
        uDMAChannelControlSet(UDMA0_BASE, UDMA_PRI_SELECT | channel, control);
    }

    command void DMAChannel.transferSet[uint8_t channel](uint32_t mode,
            void* srcAddr, void* dstAddr, uint32_t transferSize) {
        mustBeOn();
        uDMAChannelTransferSet(UDMA0_BASE, UDMA_PRI_SELECT | channel, mode, srcAddr,
                dstAddr, transferSize);
    }

    command void DMAChannel.enable[uint8_t channel]() {
        mustBeOn();
        uDMAChannelEnable(UDMA0_BASE, channel);
        setChannelActive(channel);
    }

    command bool DMAChannel.isEnabled[uint8_t channel]() {
        mustBeOn();
        return uDMAChannelIsEnabled(UDMA0_BASE, channel);
    }

    command void DMAChannel.disable[uint8_t channel]() {
        mustBeOn();
        uDMAChannelDisable(UDMA0_BASE, channel);
        setChannelInactive(channel);
    }

    async event void DMASwInt.triggered() {
        // We assume that the users of the DMA engine which
        // rely on this interrupt (which is generated only
        // for non-peripheral transfers) will also have their
        // handlers connected here and that they check flags
        // accordingly. Therefore we don't do anything here,
        // but our initialization code enabled the interrupt
        // and we assume that the other users won't even try
        // to disable it.
    }

    async event void DMAErrInt.triggered() {
        // We don't handle DMA interrupts gently, it would need
        // too complex logic.
        panic("Fatal error from uDMA Engine");
    }
}
