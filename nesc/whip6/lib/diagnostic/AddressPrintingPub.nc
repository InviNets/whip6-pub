/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "ieee154/ucIeee154AddressTypes.h"
#include "ipv6/ucIpv6AddressTypes.h"

module AddressPrintingPub {}
implementation{

    void printf_ipv6(whip6_ipv6_addr_t const *ipv6Addr) @C() {
        uint8_t i;
        union { // Endianness reverser
            uint16_t s;
            uint8_t b[2];
        } rev;
        for (i = 0; i < 8; i++) {
            rev.b[0] = ipv6Addr->data8[i * 2 + 1];
            rev.b[1] = ipv6Addr->data8[i * 2];
            printf("%X", rev.s);
            if (i < 7)
                printf(":");
        }

        //uint8_t i;
        //for (i = 0; i < 16; i++) {
        //    printf("%02X", (int)ipv6Addr->data8[i]);
        //    if (i % 2 == 1 && i < 15)
        //        printf(":");
        //}
        //printf("\n");
    }

    void printf_ieee154(whip6_ieee154_addr_t const *addr) @C() {
        if (addr->mode == IEEE154_ADDR_MODE_SHORT) {
            uint8_t i;
            printf("SHRT:");
            for (i = 0; i < 2; i++)
                printf("%02X", (int)addr->vars.shrt.data[2 - i - 1]);
        }
        else if(addr->mode == IEEE154_ADDR_MODE_EXT) {
            uint8_t i;
            printf("EXT:");
            for (i = 0; i < 8; i++)
                printf("%02X", (int)addr->vars.ext.data[8 - i - 1]);
        }
        else
            printf("ADDR:NONE");
    }

}
