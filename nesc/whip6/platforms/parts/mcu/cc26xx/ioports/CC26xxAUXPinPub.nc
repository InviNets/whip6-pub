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
 * @author Szymon Acedanski
 */

#include "gpio.h"
#include "ioc.h"
#include "chipinfo.h"

static const uint8_t mapping7x7[32] = {
    15, 14, 13, 12, 11, 10, 9, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, 7, 6, 5, 4, 3, 2, 1, 0, -1
};

static const uint8_t mapping5x5[32] = {
    12, 11, 10, 9, 8, -1, -1, 7, 6, 4, 5, 3, 2, 1, 0, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
};

static const uint8_t mapping4x4[32] = {
    10, 9, 8, -1, -1, 7, 6, 5, 4, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
};

generic module CC26xxAUXPinPub() {
    provides interface CC26xxAUXPin;
    uses interface CC26xxPin @exactlyonce();
}

implementation {
    inline event void CC26xxPin.configure() {
        IOCPinTypeAux(call CC26xxPin.IOId());
    }

    static int IOId2AUXId() {
        const uint8_t* table;
        if (ChipInfo_PackageTypeIs7x7()) {
            table = mapping7x7;
        } else if (ChipInfo_PackageTypeIs5x5()) {
            table = mapping5x5;
        } else if (ChipInfo_PackageTypeIs4x4()) {
            table = mapping4x4;
        } else {
            panic();
        }
        return table[call CC26xxPin.IOId()];
    }

    async command inline uint32_t CC26xxAUXPin.AUXIOId() {
        static int AUXId = -1;
        if (AUXId == -1) {
            AUXId = IOId2AUXId();
            if (AUXId == -1) {
                panic();
            }
        }
        return AUXId;
    }
}
