/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucString.h>
#include <ieee154/ucIeee154AddressManipulation.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX int8_t whip6_ieee154AddrAnyCmp(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    int8_t                               modeDiff;

    modeDiff = (int8_t)(addr1->mode - addr2->mode);
    if (modeDiff != 0)
    {
        return modeDiff;
    }
    switch (addr1->mode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        return whip6_shortMemCmp(
                &(addr1->vars.shrt.data[0]),
                &(addr2->vars.shrt.data[0]),
                IEEE154_SHORT_ADDR_BYTE_LENGTH
        );
    case IEEE154_ADDR_MODE_EXT:
        return whip6_shortMemCmp(
                &(addr1->vars.ext.data[0]),
                &(addr2->vars.ext.data[0]),
                IEEE154_EXT_ADDR_BYTE_LENGTH
        );
    }
    return 0;
}
