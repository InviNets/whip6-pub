/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"

generic module ThisIeee154ExtAddrAlwaysListensPrv(
        uint8_t msb_0,
        uint8_t msb_1,
        uint8_t msb_2,
        uint8_t msb_3,
        uint8_t msb_4,
        uint8_t msb_5,
        uint8_t msb_6,
        uint8_t msb_7)
{
    provides interface Ieee154KnownPassiveListners;
}
implementation
{
    command bool_disjunction Ieee154KnownPassiveListners.isPassiveListner(
            whip6_ieee154_addr_t const *addr) {
        return addr->mode == IEEE154_ADDR_MODE_EXT &&
            addr->vars.ext.data[0] == msb_7 &&
            addr->vars.ext.data[1] == msb_6 &&
            addr->vars.ext.data[2] == msb_5 &&
            addr->vars.ext.data[3] == msb_4 &&
            addr->vars.ext.data[4] == msb_3 &&
            addr->vars.ext.data[5] == msb_2 &&
            addr->vars.ext.data[6] == msb_1 &&
            addr->vars.ext.data[7] == msb_0;
    }
}

