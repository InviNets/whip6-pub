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
#define QUEUE_SIZE 10

module CherryMoteHWTestRadioServerPrv {
    uses interface Boot;

    uses interface Init as LowInit;
    uses interface RawFrame;
    uses interface RawFrameSender as LowFrameSender;
    uses interface RawFrameReceiver as LowFrameReceiver;
    uses interface LocalIeeeEui64Provider;
}

implementation {
    platform_frame_t txFr, rxFr;

    uint8_t addrQueue[QUEUE_SIZE][IEEE_EUI64_BYTE_LENGTH];

    int qHead = 0;
    int qTail = 0;

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
                int queryLen = strlen(QUERY);
                if (memcmp(QUERY, (const char*)data, queryLen) == 0) {
                    if ((qHead + 1) % QUEUE_SIZE != qTail) {
                        memcpy(addrQueue[qHead], &data[queryLen], IEEE_EUI64_BYTE_LENGTH);
                        qHead = (qHead + 1) % QUEUE_SIZE;
                        shouldSend = 1;
                    }
                    else
                        printf("Response queue full\n");
                }
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

        if (qHead != qTail) {
            call RawFrame.setLength(&txFr, FRAME_LENGTH);

            data = call RawFrame.getData(&txFr);
            snprintf((char*)data, MAX_DATA_FRAME_LEN, "%s", RESP);
            memcpy((char*)&data[strlen(RESP)], addrQueue[qTail], IEEE_EUI64_BYTE_LENGTH);
            qTail = (qTail + 1) % QUEUE_SIZE;

            call LowFrameSender.startSending(&txFr);
        }
        else
            printf("No response in the queue to send\n");
    }
}
