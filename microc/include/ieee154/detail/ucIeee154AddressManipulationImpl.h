/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_ADDRESS_MANIPULATION_IMPL_H__
#define __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_ADDRESS_MANIPULATION_IMPL_H__

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_MANIPULATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_MANIPULATION_H__ */

#include <base/ucString.h>



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrShortCpy(
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    whip6_shortMemCpy(&(srcAddr->data[0]), &(dstAddr->data[0]), IEEE154_SHORT_ADDR_BYTE_LENGTH);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrExtCpy(
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    whip6_shortMemCpy(&(srcAddr->data[0]), &(dstAddr->data[0]), IEEE154_EXT_ADDR_BYTE_LENGTH);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrAnyCpy(
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)srcAddr,
            (uint8_t MCS51_STORED_IN_RAM *)dstAddr,
            sizeof(ieee154_addr_t)
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_ieee154AddrShortCmp(
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_shortMemCmp(
            &(addr1->data[0]),
            &(addr2->data[0]),
            IEEE154_SHORT_ADDR_BYTE_LENGTH
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_ieee154AddrExtCmp(
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_shortMemCmp(
            &(addr1->data[0]),
            &(addr2->data[0]),
            IEEE154_EXT_ADDR_BYTE_LENGTH
    );
}


WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_ieee154AddrAnyEqShrt(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr1,
        uint16_t addr2Value
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return addr1->mode == IEEE154_ADDR_MODE_SHORT &&
        addr1->vars.shrt.data[0] == (uint8_t)addr2Value &&
        addr1->vars.shrt.data[1] == (uint8_t)(addr2Value >> 8);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrAnySetShrt(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr,
        uint16_t addrValue
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    addr->mode = IEEE154_ADDR_MODE_SHORT;
    addr->vars.shrt.data[0] = (uint8_t)addrValue;
    addr->vars.shrt.data[1] = (uint8_t)(addrValue >> 8);
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrAnySetNone(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    addr->mode = IEEE154_ADDR_MODE_NONE;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154AddrAnySetBroadcast(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    addr->mode = IEEE154_ADDR_MODE_SHORT;
    addr->vars.shrt.data[0] = 0xff;
    addr->vars.shrt.data[1] = 0xff;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ieee154AddrAnyIsNone(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return addr->mode == IEEE154_ADDR_MODE_NONE;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_ieee154AddrAnyIsBroadcast(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return addr->mode == IEEE154_ADDR_MODE_SHORT &&
            addr->vars.shrt.data[0] == 0xff &&
            addr->vars.shrt.data[1] == 0xff;
}



WHIP6_MICROC_INLINE_DEF_PREFIX void whip6_ieee154PanIdCpy(
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * srcPanId,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * dstPanId
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    whip6_shortMemCpy(
            &(srcPanId->data[0]),
            &(dstPanId->data[0]),
            IEEE154_PAN_ID_BYTE_LENGTH
    );
}



WHIP6_MICROC_INLINE_DEF_PREFIX int8_t whip6_ieee154PanIdCmp(
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId1,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId2
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return whip6_shortMemCmp(
            &(panId1->data[0]),
            &(panId2->data[0]),
            IEEE154_PAN_ID_BYTE_LENGTH
    );
}


#endif /* __WHIP6_MICROC_IEEE154_DETAIL_IEEE154_ADDRESS_MANIPULATION_IMPL_H__ */
