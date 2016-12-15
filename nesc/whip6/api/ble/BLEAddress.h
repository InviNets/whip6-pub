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

#ifndef BLE_ADDRESS_H
#define BLE_ADDRESS_H

#define BLE_ADDRESS_LEN 6

typedef struct _ble_address_s {
  uint8_t bytes[BLE_ADDRESS_LEN];
} __attribute__((packed)) _ble_address_t;
typedef _ble_address_t _ble_address_t_xdata;
typedef _ble_address_t_xdata ble_address_t;

#endif
