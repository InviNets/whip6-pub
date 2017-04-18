/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef BLE_DEVICE_NAME_H
#define BLE_DEVICE_NAME_H

typedef struct _eddystone_uid_s {
  uint8_t nid[EDDYSTONE_NID_LEN];
  uint8_t bid[EDDYSTONE_BID_LEN];
} _eddystone_uid_t;
typedef _eddystone_uid_t _eddystone_uid_t_xdata;
typedef _eddystone_uid_t_xdata eddystone_uid_t;

#endif
