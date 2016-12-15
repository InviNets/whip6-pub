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

// TODO: refactor into payload generators and actual advertisers

generic module EddystoneTLMAdvertiserPrv(uint32_t intervalMs) {
    provides interface OnOffSwitch @exactlyonce();

    uses interface RawBLEAdvertiser;

    uses interface DimensionalRead<TDeciCelsius, int16_t> as Temperature
        @atmostonce();
    uses interface DimensionalRead<TMilliVolt, int16_t> as VDDDividedBy3
        @atmostonce();

    uses interface Timer<TMilli, uint32_t>;
    uses interface TimerOverflow;
    uses interface Random;

    provides interface StatsIncrementer<uint8_t> as AdvertisementsSent;
}
implementation {
    uint32_t allAdvsCounter;
    uint32_t overflowedTime;

    enum {
        EDDYSTONE_TLM_PAYLOAD_LEN = 25,
    };

    bool isOn = FALSE;

    // See here:
    // https://developer.mbed.org/teams/Bluetooth-Low-Energy/code/BLE_EddystoneBeacon_Service/
    typedef struct {
        uint8_t const_data[13];
        uint8_t vbatt[2];
        uint8_t temp[2];
        uint8_t adv_cnt[4];
        uint8_t sec_cnt[4];
    } __attribute__((packed)) _payload_t;
    typedef _payload_t _payload_t_xdata;
    typedef _payload_t_xdata payload_t;

    payload_t advPayload = {
        .const_data = { 0x02, 0x01, 0x06, 0x03, 0x03, 0xaa, 0xfe,
          0x11,  // 17 bytes, incl. 3 bytes service data header
          0x16,
          0xaa, 0xfe,
          0x20,  // Eddystone-TLM frame type
          0x00,  // Version 0x00
        }
    };

    void finishAdvertisement();
    void batReadDone(error_t status, int16_t value);
    void tempReadDone(error_t status, int16_t value);

    command error_t OnOffSwitch.on() {
        if (isOn) {
            return EALREADY;
        }
        isOn = TRUE;

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
        error_t err = call Temperature.read();
        if (err != SUCCESS) {
            tempReadDone(err, 0);
        }
    }

    void tempReadDone(error_t status, int16_t value) {
        int8_t fraction;

        if (status != SUCCESS) {
            DBGPRINTF("[EddystoneTLMAdvertiserPrv] Temperature read failed:"
                      " %d\r\n", (int)status);
            value = -1280;
        }

        // Convert to 8.8 fixed-point representation
        fraction = value % 10;
        if (fraction < 0) {
            fraction = -fraction;
        }
        advPayload.temp[0] = value / 10;
        advPayload.temp[1] = fraction * 256 / 10;

        status = call VDDDividedBy3.read();
        if (status != SUCCESS) {
            batReadDone(status, 0);
        }
    }

    event void Temperature.readDone(error_t status, int16_t value) {
        tempReadDone(status, value);
    }

    void batReadDone(error_t status, int16_t value) {
        if (status != SUCCESS) {
            DBGPRINTF("[EddystoneTLMAdvertiserPrv] Battery read failed:"
                      " %d\r\n", (int)status);
            value = 0;
        }
        value *= 3;
        advPayload.vbatt[1] = value & 0xff;
        value >>= 8;
        advPayload.vbatt[0] = value & 0xff;

        finishAdvertisement();
    }

    event void VDDDividedBy3.readDone(error_t status, int16_t value) {
        batReadDone(status, value);
    }

    void finishAdvertisement() {
        error_t err;
        uint32_t v;

        // Time in deciseconds, but for simplicity we report full second
        // resolution.
        v = call Timer.getNow() / 1024 * 10 + overflowedTime;
        advPayload.sec_cnt[3] = v & 0xff;
        v >>= 8;
        advPayload.sec_cnt[2] = v & 0xff;
        v >>= 8;
        advPayload.sec_cnt[1] = v & 0xff;
        v >>= 8;
        advPayload.sec_cnt[0] = v & 0xff;

        v = allAdvsCounter;
        advPayload.adv_cnt[3] = v & 0xff;
        v >>= 8;
        advPayload.adv_cnt[2] = v & 0xff;
        v >>= 8;
        advPayload.adv_cnt[1] = v & 0xff;
        v >>= 8;
        advPayload.adv_cnt[0] = v & 0xff;

        err = call RawBLEAdvertiser.sendAdvertisement((uint8_t_xdata*)&advPayload,
                EDDYSTONE_TLM_PAYLOAD_LEN);
        if (err != SUCCESS) {
            DBGPRINTF("[EddystoneTLMAdvertiserPrv] sendAdvertisement failed:"
                      " %d\r\n", (int)err);
            call Timer.startWithTimeoutFromNow(intervalMs);
        }
    }

    event void RawBLEAdvertiser.sendingFinished(uint8_t_xdata* payload,
            uint8_t length, error_t status) {
        if (status != SUCCESS) {
            DBGPRINTF("[EddystoneTLMAdvertiserPrv] Advertisement failed:"
                      " %d\r\n", (int)status);
        }
        call Timer.startWithTimeoutFromNow(intervalMs);
    }

    event void TimerOverflow.overflow() {
        // 2^32 / 1024 * 10
        overflowedTime += 41943040;
    }

    command void AdvertisementsSent.increment(uint8_t delta) {
        allAdvsCounter += delta;
    }

    default command error_t Temperature.read() {
        return ENOSYS;
    }

    default command error_t VDDDividedBy3.read() {
        return ENOSYS;
    }
}

#undef DBGPRINTF
