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


generic module RFCoreGPOPrv(uint8_t GPOId, uint32_t PortId) {
    provides interface RFCoreGPO @atmostonce();
}

implementation {
    async command uint32_t RFCoreGPO.GPOId() {
        return GPOId;
    }
    async command uint32_t RFCoreGPO.PortId() {
        return PortId;
    }
}
