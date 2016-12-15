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

#ifndef EDDYSTONE_UID_H
#define EDDYSTONE_UID_H

#define EDDYSTONE_NID_LEN 10
#define EDDYSTONE_BID_LEN 6

typedef struct _eddystone_uid_s {
  uint8_t nid[EDDYSTONE_NID_LEN];
  uint8_t bid[EDDYSTONE_BID_LEN];
} _eddystone_uid_t;
typedef _eddystone_uid_t _eddystone_uid_t_xdata;
typedef _eddystone_uid_t_xdata eddystone_uid_t;

#endif
