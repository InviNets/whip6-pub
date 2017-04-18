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

generic module ThisIeee154ShortAddrAlwaysListensPrv(uint16_t shortAddr)
{
    provides interface Ieee154KnownPassiveListners;
}
implementation
{
    command bool_disjunction Ieee154KnownPassiveListners.isPassiveListner(
            whip6_ieee154_addr_t const *addr) {
        return addr->mode == IEEE154_ADDR_MODE_SHORT &&
            addr->vars.shrt.data[0] == (uint8_t)shortAddr &&
            addr->vars.shrt.data[1] == (uint8_t)(shortAddr >> 8);
    }
}

