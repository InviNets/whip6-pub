/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Dawid Łazarczyk
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

#include "string.h"
#include "common.h"

module CherryMoteHWTestRadioServerPrv {
    uses interface Boot;

    uses interface Init as LowInit;
    uses interface RawFrame;
    uses interface RawFrameSender as LowFrameSender;
    uses interface RawFrameReceiver as LowFrameReceiver;
}

implementation {
    platform_frame_t txFr, rxFr;

    task void sendResp();

    event void Boot.booted() {
        call LowInit.init();
        call LowFrameReceiver.startReceiving(&rxFr);
    }

    event void LowFrameReceiver.receivingFinished(platform_frame_t *fp, error_t status) {
        int shouldSend = 0;

        if (status == SUCCESS) {
            if (FRAME_LENGTH == call RawFrame.getLength(&rxFr)) {
                uint8_t *data = call RawFrame.getData(&rxFr);
                if (memcmp(QUERY, (const char*)data, strlen(QUERY)) == 0)
                    shouldSend = 1;
            }
        }
        else
            printf("Receiving failed with status=%d\n", status);

        if (shouldSend)
            // task because there's probably a bug in the driver - it doesn't
            // work when sending immediately
            post sendResp();
        else
            // otherwise just start receiving again so that the app won't get stuck
            call LowFrameReceiver.startReceiving(&rxFr);
    }

    event void LowFrameSender.sendingFinished(platform_frame_t * framePtr, error_t status) {
        if (status != SUCCESS)
            printf("Sending failed with status=%d\n", status);
        call LowFrameReceiver.startReceiving(&rxFr);
    }

    task void sendResp() {
        uint8_t *data;
        call RawFrame.setLength(&txFr, FRAME_LENGTH);

        data = call RawFrame.getData(&txFr);
        snprintf((char*)data, MAX_DATA_FRAME_LEN, "%s", RESP);

        call LowFrameSender.startSending(&txFr);
    }
}
