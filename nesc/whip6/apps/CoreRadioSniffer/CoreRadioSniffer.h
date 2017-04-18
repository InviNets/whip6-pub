/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef CORE_RADIO_SNIFFER_H
#define CORE_RADIO_SNIFFER_H

#define IOMUX_SNIFFER_CHANNEL 2

typedef struct _sniffer_header_s {
    uint32_t timestamp_32khz;
} _sniffer_header_t;
typedef _sniffer_header_t _sniffer_header_t_xdata;
typedef _sniffer_header_t_xdata sniffer_header_t;

typedef struct _sniffer_packet_s {
    _sniffer_header_t header;
    uint8_t data[0];
} _sniffer_packet_t;
typedef _sniffer_packet_t _sniffer_packet_t_xdata;
typedef _sniffer_packet_t_xdata sniffer_packet_t;

#endif
