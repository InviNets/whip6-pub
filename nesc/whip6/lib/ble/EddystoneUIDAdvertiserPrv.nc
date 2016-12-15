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

generic module EddystoneUIDAdvertiserPrv(uint32_t intervalMs) {
    provides interface OnOffSwitch;

    uses interface RawBLEAdvertiser;
    uses interface EddystoneUIDProvider;
    uses interface EddystoneCalibratedTXPowerProvider;

    uses interface Timer<TMilli, uint32_t>;
    uses interface Random;
}
implementation {
    enum {
        EDDYSTONE_UID_PAYLOAD_LEN = 31,
    };

    bool isOn = FALSE;

    // See here:
    // https://developer.mbed.org/teams/Bluetooth-Low-Energy/code/BLE_EddystoneBeacon_Service/
    uint8_t_xdata advPayload[EDDYSTONE_UID_PAYLOAD_LEN] =
        { 0x02, 0x01, 0x06, 0x03, 0x03, 0xaa, 0xfe,
          0x17,  // 23 bytes, incl. 3 bytes service data header
          0x16,
          0xaa, 0xfe,
          0x00,  // Eddystone-UID frame type
          // Following bytes will be filled by buildPayload.
        };

    void buildPayload() {
        advPayload[12] = (uint8_t)
                call EddystoneCalibratedTXPowerProvider.getCalibratedTXPower();
        call EddystoneUIDProvider.read((eddystone_uid_t*)(advPayload + 13));
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
                EDDYSTONE_UID_PAYLOAD_LEN);
        if (err != SUCCESS) {
            DBGPRINTF("[EddystoneUIDAdvertiserPrv] sendAdvertisement failed:"
                      " %d\r\n", (int)err);
            call Timer.startWithTimeoutFromNow(intervalMs);
        }
    }

    event void RawBLEAdvertiser.sendingFinished(uint8_t_xdata* payload,
            uint8_t length, error_t status) {
        if (status != SUCCESS) {
            DBGPRINTF("[EddystoneUIDAdvertiserPrv] Sending failed:"
                      " %d\r\n", (int)status);
        }
        call Timer.startWithTimeoutFromNow(intervalMs);
    }
}

#undef DBGPRINTF
