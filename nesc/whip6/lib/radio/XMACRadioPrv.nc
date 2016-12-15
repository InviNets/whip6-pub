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

//
// Some assumptions:
//
// 1. Receiving must be active also when transmitting.
//

#include "Assert.h"

#define XMAC_DEBUG 0

#if XMAC_DEBUG
#define dbgprintf printf
#else
#define dbgprintf(...)
#endif

module XMACRadioPrv {
    provides interface Init;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface XMACControl;

    uses interface Init as LowInit;
    uses interface RawFrame;
    uses interface RawFrameSender as LowFrameSender;
    uses interface RawFrameReceiver as LowFrameReceiver;
    uses interface XMACFrame;
    uses interface Timer<T32khz, uint32_t>;
}
implementation {
    typedef enum {
        STATE_UNINITIALIZED,
        STATE_OFF,
        STATE_RX_SLEEP,
        STATE_RX_STROBE_WAIT,
        STATE_RX_ACK,
        STATE_RX_DATA_WAIT,
        STATE_RX_DATA_WAIT_MORE,
        STATE_RX_DONE,
        STATE_TX_STROBE,
        STATE_TX_ACK_WAIT,
        STATE_TX_BACKOFF,
        STATE_TX_DATA,
        STATE_TX_DONE,
        STATE_ERR_RX_STUCK,
        STATE_NO_XMAC,
    } state_t;

    platform_frame_t controlFrame;
    platform_frame_t* txFrame = NULL;
    platform_frame_t* rxFrame = NULL;
    state_t state = STATE_UNINITIALIZED;
    uint8_t strobesLeft;

    #define XMAC_TICKS_PER_S 32768
    #define XMAC_DEFAULT_LISTENING_INTERVAL_MS 500
    #define XMAC_DEFAULT_LISTENING_TIME_MS 20

    uint32_t listeningInterval = XMAC_DEFAULT_LISTENING_INTERVAL_MS * XMAC_TICKS_PER_S / 1000;
    uint32_t listeningTime = XMAC_DEFAULT_LISTENING_TIME_MS * XMAC_TICKS_PER_S / 1000;
    uint32_t strobeInterval;
    uint32_t numStrobes;

    task void beat();
    void sleepRadio();
    void endTX(error_t err);
    void sendStrobe();
    void sendData();
    void endRX(error_t err);
    void tryToRXTX();
    void restartLowRX();
    bool isInRXState();
    bool isInTXState();

    command error_t Init.init() {
        state = STATE_NO_XMAC;
        strobeInterval = listeningTime / 2;
        numStrobes = (listeningInterval + listeningTime) / strobeInterval + 1;
        //post beat();
        return call LowInit.init();
    }

    void print_status() {
        dbgprintf("s%d\r\n", (int)state);
    }

    task void beat() {
        static uint8_t prev_state;
        if (state != prev_state) {
            if (prev_state == 2 && state == 3)
                goto outtt;
            if (prev_state == 3 && state == 2)
                goto outtt;
            print_status();
            prev_state = state;
        }
    outtt:
        post beat();
    }

    event void Timer.fired() {
        switch (state) {
            case STATE_RX_SLEEP:
                state = STATE_RX_STROBE_WAIT;
                tryToRXTX();
                break;

            case STATE_RX_STROBE_WAIT:
                sleepRadio();
                break;

            case STATE_RX_DATA_WAIT:
                sleepRadio();
                break;

            case STATE_RX_DATA_WAIT_MORE:
                state = STATE_OFF;
                break;

            case STATE_TX_ACK_WAIT:
                if (--strobesLeft == 0) {
                    endTX(ENOACK);
                } else {
                    sendStrobe();
                }
                break;

            case STATE_TX_BACKOFF:
                sendData();
                break;

            default:
                // ignore
        }
    }

    // ---- TX

    void endTX(error_t err) {
        platform_frame_t* frame = txFrame;
        CHECK(call LowFrameSender.isSending() == FALSE);
        if (state == STATE_NO_XMAC) {
            // do nothing
        } else {
            state = STATE_TX_DONE;
            if (!call LowFrameReceiver.isReceiving()) {
                // This can happen if reception failed during a TX state.
                // This error should be singaled before sendingFinished.
                CHECK(err != SUCCESS);
                endRX(err);
            }
        }
        txFrame = NULL;
        signal RawFrameSender.sendingFinished(frame, err);
        if (state == STATE_TX_DONE) {
            sleepRadio();
        }
    }

    inline bool isInTXState() {
        return state >= STATE_TX_STROBE && state <= STATE_TX_DONE;
    }

    void sendStrobe() {
        error_t err;
        state = STATE_TX_STROBE;
        err = call LowFrameSender.startSending(&controlFrame);
        if (err != SUCCESS) {
            if (err == EBUSY || err == ERETRY) {
                state = STATE_TX_ACK_WAIT;
                call Timer.startWithTimeoutFromLastTrigger(strobeInterval);
            } else {
                endTX(err);
                return;
            }
        }
    }

    void sendData() {
        error_t err;
        state = STATE_TX_DATA;
        err = call LowFrameSender.startSending(txFrame);
        if (err != SUCCESS) {
            endTX(err);
        }
    }

    void startBackoff(){
        state = STATE_TX_BACKOFF;
        // FIXME: *RANDOM* backoff
        call Timer.startWithTimeoutFromNow(listeningTime/4);
    }

    task void RXTXTask() {
        tryToRXTX();
    }

    command error_t RawFrameSender.startSending(platform_frame_t* frame) {
        if (state == STATE_UNINITIALIZED) {
            return EOFF;
        }
        if (frame == NULL) {
            return EINVAL;
        }
        if (txFrame != NULL) {
            return EBUSY;
        }
        txFrame = frame;
        if (state != STATE_NO_XMAC) {
            call XMACFrame.generateStrobe(frame, &controlFrame);
            strobesLeft = numStrobes;
        }
        post RXTXTask();
        return SUCCESS;
    }

    command error_t RawFrameSender.cancelSending(platform_frame_t* frame) {
        if (txFrame == NULL || txFrame != frame) {
            return EINVAL;
        }
        if (state == STATE_NO_XMAC) {
            txFrame = NULL;
            return call LowFrameSender.cancelSending(frame);
        }
        // TODO: implement
        return ENOSYS;
    }

    command bool RawFrameSender.isSending() {
        return rxFrame != NULL;
    }

    event void LowFrameSender.sendingFinished(platform_frame_t* frame,
            error_t error) {
        if (state == STATE_NO_XMAC) {
            endTX(error);
            return;
        }

        CHECK(state == STATE_TX_STROBE || state == STATE_TX_DATA
                || state == STATE_RX_ACK);

        if (error != SUCCESS) {
            if (state == STATE_RX_ACK) {
                endRX(error);
            } else if (state == STATE_TX_STROBE
                    && (error == EBUSY || error == ERETRY)) {
                state = STATE_TX_ACK_WAIT;
                call Timer.startWithTimeoutFromLastTrigger(strobeInterval);
            } else if (state == STATE_TX_STROBE || state == STATE_TX_DATA) {
                endTX(error);
            } else {
                // Should never happen, but in this case we just ignore the
                // spurious sendingFinished.
            }
            return;
        }

        switch (state) {
            case STATE_RX_ACK:
                state = STATE_RX_DATA_WAIT;
                restartLowRX();
                call Timer.startWithTimeoutFromNow(listeningTime);
                break;

            case STATE_TX_STROBE:
                state = STATE_TX_ACK_WAIT;
                restartLowRX();
                call Timer.startWithTimeoutFromLastTrigger(strobeInterval);
                break;

            case STATE_TX_DATA:
                endTX(SUCCESS);
                break;

            default:
                panic();
        }
    }

    // ---- RX

    void endRX(error_t err) {
        platform_frame_t* frame = rxFrame;
        rxFrame = NULL;
        CHECK(call LowFrameSender.isSending() == FALSE);
        CHECK(isInRXState() || state == STATE_NO_XMAC);
        if (state == STATE_NO_XMAC) {
            // do nothing
        } else if (call LowFrameReceiver.isReceiving()) {
            error_t rcv_err;
            CHECK(err != SUCCESS);
            rcv_err = call LowFrameReceiver.cancelReceiving(rxFrame);
            if (rcv_err != SUCCESS) {
                state = STATE_ERR_RX_STUCK;
            } else {
                state = STATE_OFF;
            }
        } else if (err == SUCCESS && state == STATE_RX_DATA_WAIT
                && txFrame == NULL) {
            state = STATE_RX_DATA_WAIT_MORE;
        } else {
            state = STATE_OFF;
        }
        if (frame != NULL) {
            signal RawFrameReceiver.receivingFinished(frame, err);
        }
    }

    inline bool isInRXState() {
        return (state >= STATE_RX_SLEEP && state <= STATE_RX_DATA_WAIT_MORE)
                || state == STATE_ERR_RX_STUCK;
    }

    void restartLowRX() {
        error_t err;
        if (call LowFrameReceiver.isReceiving()) {
            return;
        }
        err = call LowFrameReceiver.startReceiving(rxFrame);
        if (err != SUCCESS) {
            if (isInRXState()) {
                endRX(err);
            } else if (isInTXState()) {
                endTX(err);
            }
        }
    }

    void tryToRXTX() {
        uint32_t t0;

        if (state == STATE_NO_XMAC) {
            if (rxFrame != NULL && !call LowFrameReceiver.isReceiving()) {
                error_t err = call LowFrameReceiver.startReceiving(rxFrame);
                if (err != SUCCESS) {
                    endRX(err);
                }
            }
            if (txFrame != NULL && !call LowFrameSender.isSending()) {
                error_t err = call LowFrameSender.startSending(txFrame);
                if (err != SUCCESS) {
                    endTX(err);
                }
            }
            return;
        }

        if (rxFrame == NULL) {
            return;
        }

        // TODO: maybe not do TX in the middle of RX

        // By default we count the waiting duration relative to the theoretical
        // moment when the timer fired.
        t0 = call Timer.getLastTrigger();

        // Start transmission if at all possible
        if (txFrame != NULL && !isInTXState()) {
            t0 = call Timer.getNow();
            sendStrobe();
            return;
        }

        if (state == STATE_OFF) {
            t0 = call Timer.getNow();
            state = STATE_RX_STROBE_WAIT;
        }

        // If the user immediately called startReceiving after
        // receivingFinished.
        if (state == STATE_RX_DATA_WAIT_MORE) {
            state = STATE_RX_DATA_WAIT;
        }

        if (state == STATE_RX_STROBE_WAIT || state == STATE_RX_DATA_WAIT) {
            error_t err = call LowFrameReceiver.startReceiving(rxFrame);
            if (err != SUCCESS) {
                endRX(err);
            } else {
                call Timer.startWithTimeoutFromTime(t0, listeningTime);
            }
        }
    }

    void sleepRadio() {
        if (call LowFrameReceiver.isReceiving()) {
            error_t err = call LowFrameReceiver.cancelReceiving(rxFrame);
            if (err != SUCCESS) {
                endRX(err);
                return;
            }
        }
        state = STATE_RX_SLEEP;
        call Timer.startWithTimeoutFromLastTrigger(
                listeningInterval - listeningTime);
    }

    void sendAck() {
        error_t err;
        call XMACFrame.generateAck(rxFrame, &controlFrame);
        err = call LowFrameSender.startSending(&controlFrame);
        if (err != SUCCESS) {
            endRX(err);
        }
    }

    command error_t RawFrameReceiver.startReceiving(platform_frame_t* frame) {
        if (state == STATE_UNINITIALIZED) {
            return EOFF;
        }
        if (frame == NULL) {
            return EINVAL;
        }
        if (rxFrame != NULL) {
            return EBUSY;
        }
        rxFrame = frame;
        post RXTXTask();
        return SUCCESS;
    }

    command error_t RawFrameReceiver.cancelReceiving(platform_frame_t* frame) {
        error_t err;
        if (rxFrame == NULL || rxFrame != frame) {
            return EINVAL;
        }
        if (!(state == STATE_RX_SLEEP || state == STATE_RX_STROBE_WAIT
                || state == STATE_TX_DONE || state == STATE_NO_XMAC)) {
            // TODO: handle other cases
            return ERETRY;
        }
        CHECK(txFrame == NULL || state == STATE_NO_XMAC);
        err = call LowFrameReceiver.cancelReceiving(frame);
        if (err == SUCCESS) {
            if (state != STATE_NO_XMAC) {
                state = STATE_OFF;
            }
            rxFrame = NULL;
        }
        return err;
    }

    command bool RawFrameReceiver.isReceiving() {
        return rxFrame != NULL;
    }

    event void LowFrameReceiver.receivingFinished(platform_frame_t* frame,
            error_t error) {
        uint8_t i;
#if XMAC_DEBUG
        uint8_t_xdata* p = call RawFrame.getData(frame);
#endif
        CHECK(frame == rxFrame);

        if (state == STATE_NO_XMAC) {
            endRX(error);
            return;
        }

        dbgprintf("xmacrx %d:", error);
        for (i=0; i<5; i++) {
            dbgprintf(" %02x", p[i]);
        }
        dbgprintf("\r\n");

        if (error != SUCCESS) {
            goto restart;
        }

        if (!call XMACFrame.isXMACFrame(frame)) {
            dbgprintf("not xmac\r\n");
            if (state == STATE_RX_STROBE_WAIT
                    || state == STATE_RX_DATA_WAIT
                    || state == STATE_RX_DATA_WAIT_MORE) {
                endRX(SUCCESS);
            } else {
                // We ignore unexpected frames.
                goto restart;
            }
            return;
        }

        switch (state) {
            case STATE_RX_STROBE_WAIT:
                if (call XMACFrame.isStrobeForMe(frame)) {
                    state = STATE_RX_ACK;
                    sendAck();
                }
                break;

            case STATE_TX_ACK_WAIT:
                if (call XMACFrame.isMatchingAck(txFrame, frame)) {
                    startBackoff();
                }
                break;

            default:
                panic();
        }

    restart:
        restartLowRX();
    }

    // ---- Control

    command void XMACControl.enableXMAC() {
        if (state != STATE_NO_XMAC) {
            return;
        }
        state = STATE_OFF;
        call Timer.stop();
        if (txFrame) {
            platform_frame_t* frame = txFrame;
            // We ignore the error, as there is nothing to do with it here.
            call LowFrameSender.cancelSending(txFrame);
            txFrame = NULL;
            signal RawFrameSender.sendingFinished(frame, ECANCEL);
        }
        tryToRXTX();
    }

    command void XMACControl.disableXMAC() {
        if (state == STATE_NO_XMAC) {
            return;
        }
        state = STATE_NO_XMAC;
        call Timer.stop();
        if (call LowFrameSender.isSending()) {
            // We ignore the error, as there is nothing to do with it here.
            call LowFrameSender.cancelSending(txFrame);
        }
        if (txFrame) {
            platform_frame_t* frame = txFrame;
            txFrame = NULL;
            signal RawFrameSender.sendingFinished(frame, ECANCEL);
        }
        tryToRXTX();
    }
}

#undef dbgprintf
