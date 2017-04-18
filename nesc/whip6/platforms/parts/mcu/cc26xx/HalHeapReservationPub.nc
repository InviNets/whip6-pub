/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic module HalHeapReservationPub(size_t size) {
}
implementation {
    uint8_t reservation[size] __attribute__((used, section(".heap")));

    void do_not_optimize_out_reservation() @spontaneous() {
        reservation[0] = 1;
    }
}
