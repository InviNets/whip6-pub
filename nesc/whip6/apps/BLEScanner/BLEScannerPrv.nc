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

module BLEScannerPrv {
    uses interface Boot;
    uses interface RawBLEScanner;
    uses interface Timer<TMilli, uint32_t> as InitTimer;
}

implementation {
    event void Boot.booted() {
        printf("[BLEScannerPrv] Booting...\r\n");
        call InitTimer.startWithTimeoutFromNow(1024);
    }

    event void InitTimer.fired() {
        error_t err;

        printf("[BLEScannerPrv] Booted. Starting scanning.\r\n");

        err = call RawBLEScanner.startScan();
        if (err != SUCCESS) {
            printf("[BLEScannerPrv] Failed to start scanning: %d\r\n", err);
        }
    }

    event void RawBLEScanner.advertisementReceived(ble_frame_t* frame) {
        uint8_t* f = (uint8_t*)frame;
        ble_address_t* addr = &frame->pdu.adv.address;
        int i;

        printf("[BLEScannerPrv] BLE scan result: %02X:%02X:%02X:%02X:%02X:%02X,"
                " RSSI=%d.\r\n  ",
                addr->bytes[5], addr->bytes[4], addr->bytes[3], addr->bytes[2],
                addr->bytes[1], addr->bytes[0],
                frame->rssi);

        for (i = 0; i < sizeof(*frame); i++) {
            printf("%02x ", f[i]);
        }
        printf("\r\n");
    }
}
