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


generic module IOMuxFlowControlPub(int max_readers) {
    uses interface PacketWrite;
    uses interface IOFlowControlHelper;
}
implementation
{
    uint8_t_xdata packet[max_readers];
    bool writing = FALSE;
    bool state_changed = FALSE;

    void write() {
        uint8_t n = call IOFlowControlHelper.getReadyChannels(packet);
        call PacketWrite.startWrite(packet, n);
        state_changed = FALSE;
        writing = TRUE;
    }

    event void PacketWrite.writeDone(error_t result, uint8_t_xdata* buffer, uint16_t size) {
        writing = FALSE;
        if (state_changed) {
            write();
        }
    }

    event void IOFlowControlHelper.channelReady(uint8_t num) {
        state_changed = TRUE;
        if (!writing) {
            write();
        }
    }

    event void IOFlowControlHelper.channelBusy(uint8_t num) { }
}

