/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */
#include "stdio.h"

#define BUFFER_SIZE 15
#define DATA_SIZE 10
#define INTERVAL 10
#define SECOND 1000

module UARTFlowControlTestPrv {
    uses interface Boot;
    uses interface Timer<TMilli, uint32_t> as Timer1;
    uses interface Timer<TMilli, uint32_t> as Timer2;
    uses interface BufferedRead;
    uses interface BufferedWrite;
    uses interface OnOffSwitch @exactlyonce();
}

implementation {
    uint8_t bufferIn[BUFFER_SIZE];
    uint8_t bufferOut[BUFFER_SIZE];
    uint8_t isActive = -1;
    uint8_t time = 0;

    void toggleIO();
    task void askToRead();

    event void Boot.booted() {
        call OnOffSwitch.off();

        snprintf((char *) bufferOut, DATA_SIZE, "ala ma psa");

        toggleIO();
    }

    void toggleIO() {
        isActive = !isActive;
        call BufferedRead.setActive(isActive);

        if (isActive) {
            printf(">> reading and writing ON\n\r");
            call BufferedRead.startRead(bufferIn, DATA_SIZE);
            call BufferedWrite.startWrite(bufferOut, DATA_SIZE);
        } else {
            printf(">> reading and writing OFF\n\r");
        }

        time = INTERVAL;
        call Timer2.startWithTimeoutFromNow(SECOND);
        call Timer1.startWithTimeoutFromNow(INTERVAL * SECOND);
    }

    event void Timer1.fired() {
        toggleIO();
    }

    event void Timer2.fired() {
        if (isActive) {
            printf("ON: %d\n\r", --time);
        } else {
            printf("OFF: %d\n\r", --time);
        }
        call Timer2.startWithTimeoutFromNow(SECOND);
    }

    event void BufferedRead.bytesLost(uint16_t lostCount) {
        printf("bytes lost: %d\n", (int)lostCount);
    }

    event void BufferedRead.readDone(uint8_t *buffer, uint16_t capacity) {
        printf("reading done: %s\n\r", buffer);
        post askToRead();
    }

    event void BufferedWrite.writeDone(error_t result, uint8_t *buffer, uint16_t size) {
        printf("writing done: %d\n\r", result);
    }

    task void askToRead() {
        call BufferedRead.startRead(bufferIn, DATA_SIZE);
    }
}
