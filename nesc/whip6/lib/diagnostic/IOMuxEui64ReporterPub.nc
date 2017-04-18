/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * 
 * A component which provides a way to read the EUI-64 of the device,
 * by sending a packet with a single character '?'. The reply will
 * contain just the EUI-64.
 */
generic module IOMuxEui64ReporterPub() {
    provides interface Init @exactlyonce();
    uses interface PacketWrite @exactlyonce();
    uses interface PacketRead @exactlyonce();
    uses interface LocalIeeeEui64Provider @exactlyonce();
}
implementation{
    ieee_eui64_t myEui;
    char buf;

    command error_t Init.init() {
        call LocalIeeeEui64Provider.read(&myEui);
        return call PacketRead.startRead((uint8_t_xdata*) &buf, 1);
    }

    event void PacketRead.readDone(uint8_t_xdata *buffer, uint16_t size) {
        if (size == 1 && buf == '?') {
            call PacketWrite.startWrite((uint8_t_xdata*)&myEui, sizeof(myEui));
        }
        call PacketRead.startRead((uint8_t_xdata*) &buf, 1);
    }

    event inline void PacketWrite.writeDone(error_t result, uint8_t_xdata *buffer, uint16_t size) { }
}
