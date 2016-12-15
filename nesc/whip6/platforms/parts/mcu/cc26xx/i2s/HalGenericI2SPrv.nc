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


#include <stdio.h>
#include <driverlib/i2s.h>

#define WARNPRINTF printf
#define DBGPRINTF printf

generic module HalGenericI2SPrv(uint32_t i2sBase, size_t bufSize) {
    provides interface AudioInput;

    uses interface ExternalEvent as Interrupt @exactlyonce();
    uses interface OnOffSwitch;
    uses interface AskBeforeSleep @exactlyonce();
    uses interface HalI2SSampleSize;
}

implementation {
    enum {
        CHUNK_SIZE_SAMPLES = 64,
    };

    typedef enum {
        STATE_STOPPED,
        STATE_STARTING,  // Ignoring initial zeros from the mic
        STATE_STARTED,
        STATE_STOPPING,
        STATE_STOPPING_DONE,
    } state_t;

    state_t state = STATE_STOPPED;

    norace uint8_t currChunk;
    norace error_t currError;

    norace uint16_t chunksToSignal;
    norace uint16_t chunksPerSignal;
    norace uint8_t chunkSize;

    uint8_t buf[bufSize] __attribute__((aligned(2)));

    int pendingSignals;

    size_t ignoredChunks;

    command error_t AudioInput.start() {
        atomic {
            if (state != STATE_STOPPED) {
                return ESTATE;
            }
        }

        chunkSize = CHUNK_SIZE_SAMPLES * call HalI2SSampleSize.getSampleSizeInBytes();
        if (bufSize % (2 * chunkSize)) {
            return ESIZE;
        }

        atomic {
            state = STATE_STARTING;
            pendingSignals = 0;
        }

        call OnOffSwitch.on();

        chunksPerSignal = bufSize / chunkSize / 2;
        chunksToSignal = chunksPerSignal;

        currChunk = 0;
        currError = SUCCESS;

        ignoredChunks = 0;

        I2SSampleStampConfigure(i2sBase, true, false);
        I2SBufferConfig(i2sBase, (uint32_t)buf, (uint32_t)NULL,
                CHUNK_SIZE_SAMPLES, bufSize);

        // At first, we will be ignoring empty chunks until receiving
        // some data which looks like audio. Until then, we reload the
        // DMA pointer with the beginning of buf continuously.
        buf[0] = buf[1] = buf[2] = buf[3] = 0x00;
        I2SEnable(i2sBase);
        I2SPointerSet(i2sBase, true, buf);

        I2SIntEnable(i2sBase, I2S_INT_ALL);
        I2SIntClear(i2sBase, I2S_INT_ALL);
        I2SSampleStampEnable(i2sBase);
        call Interrupt.clearPending();
        call Interrupt.asyncNotifications(TRUE);

        return SUCCESS;
    }

    void stop() {
        I2SIntDisable(i2sBase, I2S_INT_ALL);
        call Interrupt.asyncNotifications(FALSE);
        I2SSampleStampDisable(i2sBase);
        I2SDisable(i2sBase);
        atomic state = STATE_STOPPED;
        call OnOffSwitch.off();
        signal AudioInput.stopped(currError);
    }

    command error_t AudioInput.requestStop() {
        atomic {
            if (state != STATE_STARTED && state != STATE_STARTING) {
                return EALREADY;
            }
            state = STATE_STOPPING;
        }
        return SUCCESS;
    }

    task void process() {
        state_t readState;
        int readPendingSignals;
        atomic {
            readState = state;
            readPendingSignals = pendingSignals;
            pendingSignals = 0;
        }
        if (readPendingSignals > 1) {
            WARNPRINTF("[HalGenericI2SPrv] Dropped %d chunks due to "
                    "overrun\r\n", readPendingSignals - 1);
        }
        while (readPendingSignals > 1) {
            currChunk = (currChunk + chunksPerSignal) % (bufSize /
                    chunkSize);
            readPendingSignals--;
        }
        switch (readState) {
            case STATE_STARTED:
                {
                    uint8_t* data = buf + currChunk * chunkSize;
                    size_t len = chunksPerSignal * chunkSize;

                    /* Just after power-on we ignore samples until we get some
                     * data which looks like real data. */
                    if (ignoredChunks) {
                        DBGPRINTF("[HalGenericI2SPrv] Ignored %d "
                                "empty chunks at start\r\n",
                                ignoredChunks);
                        ignoredChunks = 0;
                    }
                    signal AudioInput.chunkReady(data, len);
                    currChunk = (currChunk + chunksPerSignal) % (bufSize /
                            chunkSize);
                }
                break;
            case STATE_STOPPING:
                // Do nothing
                break;
            case STATE_STOPPING_DONE:
                stop();
                break;
            default:
                panic();
                break;
        }
    }

    async event void Interrupt.triggered() {
        bool spurious = TRUE;
        uint32_t status = I2SIntStatus(i2sBase, true);
        I2SIntClear(i2sBase, status);

        if (status & I2S_INT_DMA_IN) {
            spurious = FALSE;
            if (state == STATE_STARTING) {
                if ((buf[0] == 0 || buf[0] == 0xff) &&
                        (buf[1] == 0 || buf[1] == 0xff) &&
                        (buf[2] == 0 || buf[2] == 0xff) &&
                        (buf[3] == 0 || buf[3] == 0xff)) {
                    ignoredChunks++;
                    I2SPointerSet(i2sBase, true, buf);
                } else {
                    I2SPointerUpdate(i2sBase, true);
                    state = STATE_STARTED;
                }
            } else if (state == STATE_STARTED) {
                // TODO: support buffer overrun somehow
                I2SPointerUpdate(i2sBase, true);
                if (--chunksToSignal == 0) {
                    post process();
                    atomic pendingSignals++;
                    chunksToSignal = chunksPerSignal;
                }
            }
        }

        if (status & I2S_INT_PTR_ERR) {
            spurious = FALSE;
            if (state != STATE_STOPPING) {
                currError = EIO;
            }
            state = STATE_STOPPING_DONE;
            post process();
        }

        if (status & I2S_INT_WCLK_ERR) {
            panic("Unexpected I2S_INT_WCLK_ERR");
        }

        if (status & I2S_INT_TIMEOUT) {
            panic("Unexpected I2S_INT_TIMEOUT");
        }

        if (status & I2S_INT_BUS_ERR) {
            panic("Unexpected I2S_INT_BUS_ERR");
        }

        if (spurious) {
            panic("Spurious I2S interrupt");
        }
    }

    event inline sleep_level_t AskBeforeSleep.maxSleepLevel() {
        return (state == STATE_STOPPED) ? SLEEP_LEVEL_DEEP : SLEEP_LEVEL_IDLE;
    }
}

#undef WARNPRINTF
#undef DBGPRINTF
