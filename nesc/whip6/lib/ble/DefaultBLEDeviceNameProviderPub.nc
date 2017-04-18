/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

generic module DefaultBLEDeviceNameProviderPub(char defaultShortName[]) {
    provides interface BLEDeviceNameProvider;
    uses interface BLEDeviceNameProvider as Override;
}
implementation {
    command const char* BLEDeviceNameProvider.getShortName() {
        return call Override.getShortName();
    }

    command const char* BLEDeviceNameProvider.getFullName() {
        return call Override.getFullName();
    }

    default command const char* Override.getShortName() {
        return defaultShortName;
    }

    default command const char* Override.getFullName() {
        return call Override.getShortName();
    }
}
