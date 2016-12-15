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

#define DBGPRINTF printf
//#define DBGPRINTF(...)

generic module BLEDeviceNameAdvertiserPrv(uint32_t intervalMs) {
    provides interface OnOffSwitch;

    uses interface RawBLEAdvertiser;
    uses interface BLEDeviceNameProvider;

    uses interface Timer<TMilli, uint32_t>;
    uses interface Random;
}
implementation {
    enum {
        BLE_DEVICE_NAME_PAYLOAD_HEADER_LEN = 5,
        BLE_DEVICE_NAME_PAYLOAD_LEN = 31,
    };

    bool isOn = FALSE;

    // See here:
    // https://developer.mbed.org/teams/Bluetooth-Low-Energy/code/BLE_EddystoneBeacon_Service/
    uint8_t_xdata advPayload[BLE_DEVICE_NAME_PAYLOAD_LEN] =
        { 0x02, 0x01, 0x06, 0xff, 0x09 };
    uint8_t advPayloadLen;

    void buildPayload() {
        const char* name = call BLEDeviceNameProvider.getShortName();
        advPayloadLen = strlen(name);
        memcpy(advPayload + 5, name, advPayloadLen);
        advPayload[3] = advPayloadLen + 1;
        advPayloadLen += BLE_DEVICE_NAME_PAYLOAD_HEADER_LEN;
    }

    command error_t OnOffSwitch.on() {
        if (isOn) {
            return EALREADY;
        }
        isOn = TRUE;

        buildPayload();
        call Timer.startWithTimeoutFromNow(intervalMs * call Random.rand16()
                / 65536);

        return SUCCESS;
    }

    command error_t OnOffSwitch.off() {
        if (!isOn) {
            return EALREADY;
        }
        isOn = FALSE;

        call Timer.stop();

        return SUCCESS;
    }

    event void Timer.fired() {
        error_t err = call RawBLEAdvertiser.sendAdvertisement(advPayload,
                advPayloadLen);
        if (err != SUCCESS) {
            DBGPRINTF("[BLEDeviceNameAdvertiserPrv] sendAdvertisement failed:"
                      " %d\r\n", (int)err);
            call Timer.startWithTimeoutFromNow(intervalMs);
        }
    }

    event void RawBLEAdvertiser.sendingFinished(uint8_t_xdata* payload,
            uint8_t length, error_t status) {
        if (status != SUCCESS) {
            DBGPRINTF("[BLEDeviceNameAdvertiserPrv] Sending failed:"
                      " %d\r\n", (int)status);
        }
        call Timer.startWithTimeoutFromNow(intervalMs);
    }
}

#undef DBGPRINTF
