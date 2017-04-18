/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <stdio.h>

generic module RawBLEAdvertiserMuxPub(int numClients) {
    provides interface RawBLEAdvertiser[uint8_t client];
    uses interface RawBLEAdvertiser as LowAdvertiser;
}
implementation {
    struct {
        uint8_t_xdata* payload;
        uint8_t length;
    } state[numClients];

    bool busy;

    void finish(uint8_t client, error_t status);

    task void process() {
        uint8_t i;
        if (busy) {
            return;
        }
        for (i = 0; i < numClients; i++) {
            if (state[i].payload != NULL) {
                error_t status;
                busy = TRUE;
                status = call LowAdvertiser.sendAdvertisement(
                        state[i].payload, state[i].length);
                if (status != SUCCESS) {
                    finish(i, status);
                }
                return;
            }
        }
    }

    void finish(uint8_t client, error_t status) {
        uint8_t_xdata* payload = state[client].payload;
        uint8_t length = state[client].length;
        busy = FALSE;
        state[client].payload = NULL;
        signal RawBLEAdvertiser.sendingFinished[client](payload, length,
                status);
        post process();
    }

    command error_t RawBLEAdvertiser.sendAdvertisement[uint8_t client](
            uint8_t_xdata* payload, uint8_t length) {
        if (payload == NULL) {
            return EINVAL;
        }
        if (state[client].payload != NULL) {
            return EBUSY;
        }
        state[client].payload = payload;
        state[client].length = length;
        post process();
        return SUCCESS;
    }

    event void LowAdvertiser.sendingFinished(uint8_t_xdata* payload,
            uint8_t length, error_t status) {
        uint8_t i;
        for (i = 0; i < numClients; i++) {
            if (state[i].payload == payload) {
                finish(i, status);
                return;
            }
        }
    }

    default event void RawBLEAdvertiser.sendingFinished[uint8_t client](
            uint8_t_xdata* payload, uint8_t length, error_t status) { }
}
