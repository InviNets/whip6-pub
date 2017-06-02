/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

#include <driverlib/osc.h>
#include "stdio.h"
#include "string.h"
#include "common.h"

#define BUFFER_SIZE 50
#define CBUFFER_SIZE 100
#define TIMEOUT_MS 1024

module HWTestPrv {
    uses interface Boot;
    uses interface BufferedRead;
    uses interface BufferedWrite;
    uses interface Led;
    uses interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;
    uses interface Timer<TMilli, uint32_t>;

    uses interface Init as LowInit;
    uses interface RawFrame;
    uses interface RawFrameSender as LowFrameSender;
    uses interface RawFrameReceiver as LowFrameReceiver;
}

implementation {
    uint16_t cmd_size = 1;
    error_t result;
    error_t init_status;
    uint8_t_xdata buffer[BUFFER_SIZE];
    char cbuffer[CBUFFER_SIZE];
    platform_frame_t txFr, rxFr;

    event void Boot.booted() {
        call Led.off();
        call BufferedRead.setActive(true);
        init_status = call LowInit.init();
        // We want to avoid printing about errors here because it can break
        // UART test - it will be delayed for later
        result = call BufferedRead.startRead(buffer, cmd_size);
        // this printf is allowed because it's an UART error anyway
        if (result != SUCCESS) {
            printf("startRead failed with status=%d\n", result);
        }
    }

    event void BufferedRead.bytesLost(uint16_t lostCount) {
        printf("Bytes lost=%d\n", (int)lostCount);
    }

    event void BufferedRead.readDone(uint8_t_xdata *buffer, uint16_t capacity) {
        int finished = 0;
        uint8_t_xdata *data;

        result = SUCCESS;

        switch (buffer[0]) {
            case TEMP_CMD:
                result = call ReadTemp.read();
                if (result != SUCCESS)
                    printf("ReadTemp.read() failed with status=%d\n", result);
                break;
            case LED_ON_CMD:
                call Led.on();
                sprintf(cbuffer, "%d\n", 1);
                call BufferedWrite.startWrite((uint8_t_xdata*)cbuffer, strlen(cbuffer));
                break;
            case XTAL_CMD:
                call Timer.startWithTimeoutFromNow(TIMEOUT_MS);
                break;
            case LED_OFF_CMD:
                call Led.off();
                sprintf(cbuffer, "%d\n", 0);
                call BufferedWrite.startWrite((uint8_t_xdata*)cbuffer, strlen(cbuffer));
                break;
            case RADIO_CMD:
                if (init_status != SUCCESS) {
                    printf("LowInit.init() failed with status=%d\n", result);
                    break;
                }
                call RawFrame.setLength(&txFr, FRAME_LENGTH);

                data = call RawFrame.getData(&txFr);
                sprintf((char*)data, query);

                result = call LowFrameSender.startSending(&txFr);
                if (result != SUCCESS)
                    printf("RADIO_CMD: LowFrameSender.startSending failed with status=%d\n", result);
                break;
            case UART_CMD:
                printf(query);
                printf("\n");
                finished = 1;
                break;
            case ICOUNT_CMD:
                finished = 1;
                printf("ICount: Not implemented error\n");
                break;
            default:
                finished = 1;
                printf("Unknown command: %c\n", buffer[0]);
        }

        if (result != SUCCESS)
            finished = 1;

        if (finished) {
            call BufferedRead.startRead(buffer, cmd_size);
        }
    }

    event void LowFrameSender.sendingFinished(platform_frame_t * framePtr, error_t status) {
        if (status == SUCCESS)
            result = call LowFrameReceiver.startReceiving(&rxFr);
        else
            printf("LowFrameSender.sendingFinished failed with status=%d\n", status);

        if (result != SUCCESS)
            printf("LowFrameReceiver.startReceiving failed with status=%d\n", result);
    }

    event void LowFrameReceiver.receivingFinished(platform_frame_t *fp, error_t status) {
        int res = 0;

        if (status == SUCCESS) {
            if (FRAME_LENGTH == call RawFrame.getLength(&rxFr)) {
                uint8_t_xdata *data = call RawFrame.getData(&rxFr);

                if (memcmp(resp, (const char*)data, strlen(resp)) == 0)
                    res = 1;
            }
        }
        else
            printf("LowFrameReceiver.receivingFinished failed with status=%d\n",
                   status);

        sprintf(cbuffer, "%d\n", res);
        call BufferedWrite.startWrite((uint8_t_xdata*)cbuffer, strlen(cbuffer));
    }
    event void Timer.fired() {
        int res = OSCClockSourceGet(OSC_SRC_CLK_LF) == OSC_XOSC_LF;
        sprintf(cbuffer, "%d\n", res);
        call BufferedWrite.startWrite((uint8_t_xdata*)cbuffer, strlen(cbuffer));
    }

    event void ReadTemp.readDone(error_t result, int16_t val) {
        if (result == SUCCESS) {
            sprintf(cbuffer, "%d\n", val);
            call BufferedWrite.startWrite((uint8_t_xdata*)cbuffer, strlen(cbuffer));
        }
        else {
            printf("ReadTemp.readDone failed with status=%d\n", result);
        }
    }

    event void BufferedWrite.writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size) {
        call BufferedRead.startRead(buffer, cmd_size);
    }
}
