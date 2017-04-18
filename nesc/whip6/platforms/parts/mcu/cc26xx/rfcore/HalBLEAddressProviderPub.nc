/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <string.h>
#include <BLEAddress.h>

module HalBLEAddressProviderPub {
    provides interface BLEAddressProvider;
}
implementation {
    command void BLEAddressProvider.read(ble_address_t* addr) {
        memcpy(addr, (void*)(FCFG1_BASE + FCFG1_O_MAC_BLE_0), BLE_ADDRESS_LEN);
    }
}
