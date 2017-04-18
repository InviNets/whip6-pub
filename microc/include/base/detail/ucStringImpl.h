/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_BASE_DETAIL_STRING_IMPL_H__
#define __WHIP6_MICROC_BASE_DETAIL_STRING_IMPL_H__

#ifndef __WHIP6_MICROC_BASE_STRING_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_BASE_STRING_H__ */


WHIP6_MICROC_PRIVATE_DEF_PREFIX char whip6_lo4bitsToHexChar(
        uint8_t b
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    switch (b & 0x0f)
    {
    case 0x00:
        return '0';
    case 0x01:
        return '1';
    case 0x02:
        return '2';
    case 0x03:
        return '3';
    case 0x04:
        return '4';
    case 0x05:
        return '5';
    case 0x06:
        return '6';
    case 0x07:
        return '7';
    case 0x08:
        return '8';
    case 0x09:
        return '9';
    case 0x0a:
        return 'a';
    case 0x0b:
        return 'b';
    case 0x0c:
        return 'c';
    case 0x0d:
        return 'd';
    case 0x0e:
        return 'e';
    default:
        return 'f';
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_shortMemCpy(
        uint8_t MCS51_STORED_IN_RAM const * src,
        uint8_t MCS51_STORED_IN_RAM * dst,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    for (; size > 0; --size, ++src, ++dst)
    {
        *dst = *src;
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_shortMemSet(
        uint8_t MCS51_STORED_IN_RAM * m,
        uint8_t pattern,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    for (; size > 0; --size, ++m) {
        *m = pattern;
    }
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX int8_t whip6_shortMemCmp(
        uint8_t MCS51_STORED_IN_RAM const * m1,
        uint8_t MCS51_STORED_IN_RAM const * m2,
        uint8_t size
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    for (; size > 0; --size, ++m1, ++m2)
    {
        int8_t tmp = (int8_t)(*m1 - *m2);
        if (tmp != 0)
        {
            return tmp;
        }
    }
    return 0;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_longMemCpy(
        uint8_t MCS51_STORED_IN_RAM const * src,
        uint8_t MCS51_STORED_IN_RAM * dst,
        size_t size
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    for (; size > 0; --size, ++src, ++dst)
    {
        *dst = *src;
    }
}



#endif /* __WHIP6_MICROC_BASE_DETAIL_STRING_IMPL_H__ */
