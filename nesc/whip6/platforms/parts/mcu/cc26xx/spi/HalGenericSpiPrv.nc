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
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include "hw_memmap.h"
#include "hw_types.h"
#include "hw_ssi.h"
#include "ssi.h"
#include "udma.h"

generic module HalGenericSpiPrv(uint32_t ssiBase) {
    provides interface SpiByte[uint8_t client];
    provides interface SpiPacket[uint8_t client];

    uses interface ExternalEvent as Interrupt @exactlyonce();
    uses interface DMAChannel as TXChannel @exactlyonce();
    uses interface DMAChannel as RXChannel @exactlyonce();
}

implementation {
    /* what we send if a higher layer passes NULL as a TX buffer */
    /* according to SpiPacket specification, this must be zero */
    uint8_t dummyTXByte = 0x00;

    /* well, we DMA the received data to this variable if the user */
    /* is not interested in the received data */
    uint8_t dummyRXByte = 0x00;

    volatile bool busy = FALSE;

    /* all variables are protected by busy */
    volatile norace uint8_t *currTxBuf;
    volatile norace uint8_t *currRxBuf;
    volatile norace uint16_t currLen;
    volatile norace uint8_t currClient;

    async command uint8_t SpiByte.write[uint8_t client](uint8_t tx) {
        uint32_t result;

        atomic {
            if (busy) {
                return 0;
            }
            busy = TRUE;
        }

        if (SSIBusy(ssiBase)) {
            panic();
        }

        // Discard any data from the FIFO
        while (SSIDataGetNonBlocking(ssiBase, &result)) /* nop */;
        SSIDataPut(ssiBase, tx);
        while (SSIBusy(ssiBase)) /* nop */;
        SSIDataGet(ssiBase, &result);
        atomic busy = FALSE;
        return result;
    }

    async command error_t SpiPacket.send[uint8_t client](uint8_t *txBuf, uint8_t *rxBuf, uint16_t len) {
        if (len == 0) {
            return EINVAL;
        }

        atomic {
            if (busy) {
                return EBUSY;
            }
            busy = TRUE;
        }

        currTxBuf = txBuf;
        currRxBuf = rxBuf;
        currLen = len;
        currClient = client;

        if (txBuf == NULL) {
            call TXChannel.controlSet(
                    UDMA_SIZE_8 | UDMA_SRC_INC_NONE | UDMA_DST_INC_NONE | UDMA_ARB_4);
            call TXChannel.transferSet(UDMA_MODE_BASIC, &dummyTXByte,
                    (void*)(ssiBase + SSI_O_DR), len);
        } else {
            call TXChannel.controlSet(
                    UDMA_SIZE_8 | UDMA_SRC_INC_8 | UDMA_DST_INC_NONE | UDMA_ARB_4);
            call TXChannel.transferSet(UDMA_MODE_BASIC, txBuf,
                    (void*)(ssiBase + SSI_O_DR), len);
        }
        if (rxBuf == NULL) {
            call RXChannel.controlSet(
                    UDMA_SIZE_8 | UDMA_SRC_INC_NONE | UDMA_DST_INC_NONE | UDMA_ARB_4);
            call RXChannel.transferSet(UDMA_MODE_BASIC, (void*)(ssiBase + SSI_O_DR),
                    &dummyRXByte, len);
        } else {
            call RXChannel.controlSet(
                    UDMA_SIZE_8 | UDMA_SRC_INC_NONE | UDMA_DST_INC_8 | UDMA_ARB_4);
            call RXChannel.transferSet(UDMA_MODE_BASIC, (void*)(ssiBase + SSI_O_DR),
                    rxBuf, len);
        }

        call Interrupt.clearPending();
        call Interrupt.asyncNotifications(TRUE);
        call TXChannel.enable();
        call RXChannel.enable();

        SSIDMAEnable(ssiBase, SSI_DMA_TX | SSI_DMA_RX);

        return SUCCESS;
    }

    async event void Interrupt.triggered() {
        bool spurious = TRUE;

        if (call TXChannel.intStatus()) {
            // Calling intStatus is important for the DMA logic to notice the
            // end of transfer and allow MCU sleep.

            SSIDMADisable(ssiBase, SSI_DMA_TX);
            call TXChannel.clearInt();
            spurious = FALSE;
        }

        if (call RXChannel.intStatus()) {
            uint8_t* txBuf = (uint8_t *)currTxBuf;
            uint8_t* rxBuf = (uint8_t *)currRxBuf;
            uint16_t len = currLen;
            uint8_t client = currClient;

            SSIDMADisable(ssiBase, SSI_DMA_RX);
            call RXChannel.clearInt();
            spurious = FALSE;

            call Interrupt.asyncNotifications(FALSE);

            atomic busy = FALSE;

            signal SpiPacket.sendDone[client](txBuf, rxBuf, len, SUCCESS);
        }

        if (spurious) {
            panic("Unexpected SSI interrupt");
        }
    }

    default async event void SpiPacket.sendDone[uint8_t client](uint8_t *txBuf, uint8_t *rxBuf, uint16_t len, error_t error) {}
}
