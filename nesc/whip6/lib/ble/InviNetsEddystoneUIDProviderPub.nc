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


module InviNetsEddystoneUIDProviderPub {
    provides interface EddystoneUIDProvider;
    uses interface BLEAddressProvider;
}
implementation
{
    // This is a truncated SHA-1 hash of invinets.com, as recommended here:
    // https://github.com/google/eddystone/tree/master/eddystone-uid#truncated-hash-of-fqdn
    const uint8_t nid[EDDYSTONE_NID_LEN] =
        { 0xe3, 0x0d, 0x51, 0xcf, 0xc1, 0x5b, 0x58, 0xe1, 0xf2, 0xb5 };

    command void EddystoneUIDProvider.read(eddystone_uid_t* uid) {
        memcpy(uid->nid, nid, EDDYSTONE_NID_LEN);

        // We use the bluetooth address as the BID, if not provided externally.
#ifndef EDDYSTONE_BID
        call BLEAddressProvider.read((ble_address_t*)uid->bid);
#else
        {
            uint32_t bid = EDDYSTONE_BID;
            uid->bid[5] = bid & 0xff;
            bid >>= 8;
            uid->bid[4] = bid & 0xff;
            bid >>= 8;
            uid->bid[3] = bid & 0xff;
            bid >>= 8;
            uid->bid[2] = bid & 0xff;
            bid >>= 8;
            uid->bid[1] = '\0';
            uid->bid[0] = '\0';
        }
#endif
    }
}
