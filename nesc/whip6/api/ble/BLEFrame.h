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

#ifndef BLE_FRAME_H
#define BLE_FRAME_H

#include <BLEAddress.h>

#define BLE_MAX_FRAME_LEN 43

typedef union _ble_pdu_s {
    struct {
        struct {
            unsigned type : 4;
            unsigned reserved1 : 2;
            unsigned TxAdd : 1;
            unsigned RxAdd : 1;
            unsigned length : 6;
            unsigned reserved0 : 2;
        } __attribute__((packed)) header;
        _ble_address_t address;
        uint8_t data[31];
    } __attribute__((packed)) adv;
    // TODO: data channel pdu.
} __attribute__((packed)) _ble_pdu_t;
typedef _ble_pdu_t _ble_pdu_t_xdata;
typedef _ble_pdu_t_xdata ble_pdu_t;

typedef struct _ble_frame_s {
    uint8_t length;
    _ble_pdu_t pdu;
    int8_t rssi;
    struct {
        unsigned crcerr : 1;
    };
    uint32_t timestamp;
} __attribute__((packed)) _ble_frame_t;
typedef _ble_frame_t _ble_frame_t_xdata;
typedef _ble_frame_t_xdata ble_frame_t;

#endif
