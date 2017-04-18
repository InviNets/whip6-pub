/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic module ConstEddystoneCalibratedTXPowerProviderPub(
        int8_t txPowerAt0Meters) {
    provides interface EddystoneCalibratedTXPowerProvider;
}
implementation {
    command int8_t EddystoneCalibratedTXPowerProvider.getCalibratedTXPower() {
        return txPowerAt0Meters;
    }
}
