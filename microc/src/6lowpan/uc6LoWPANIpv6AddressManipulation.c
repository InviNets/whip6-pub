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
#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrExt(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * ieee154Addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *         addrBytePtr;
    uint8_t MCS51_STORED_IN_RAM const *   euiBytePtr;
    uint8_t                               i;

    addrBytePtr = &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]);
    euiBytePtr = &(ieee154Addr->data[(IPV6_ADDRESS_LENGTH_IN_BYTES >> 1) - 1]);
    *addrBytePtr = (*euiBytePtr) ^ 0x02;
    for (i = (IPV6_ADDRESS_LENGTH_IN_BYTES >> 1) - 1; i > 0; --i)
    {
        ++addrBytePtr;
        --euiBytePtr;
        *addrBytePtr = (*euiBytePtr);
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *   addrBytePtr;

    addrBytePtr = &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]);
    *addrBytePtr = ieee154PanId->data[1] & ~(uint8_t)0x02;
    ++addrBytePtr;
    *addrBytePtr = ieee154PanId->data[0];
    ++addrBytePtr;
    *addrBytePtr = 0x00;
    ++addrBytePtr;
    *addrBytePtr = 0xff;
    ++addrBytePtr;
    *addrBytePtr = 0xfe;
    ++addrBytePtr;
    *addrBytePtr = 0x00;
    ++addrBytePtr;
    *addrBytePtr = ieee154Addr->data[1];
    ++addrBytePtr;
    *addrBytePtr = ieee154Addr->data[0];
    ++addrBytePtr;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrAny(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    switch (ieee154Addr->mode)
    {
    case IEEE154_ADDR_MODE_SHORT:
        whip6_ipv6AddrFillSuffixWithIeee154AddrShort(
                ipv6Addr,
                &ieee154Addr->vars.shrt,
                ieee154PanId
        );
        break;
    case IEEE154_ADDR_MODE_EXT:
        whip6_ipv6AddrFillSuffixWithIeee154AddrExt(
                ipv6Addr,
                &ieee154Addr->vars.ext
        );
        break;
    default:
        whip6_shortMemSet(
                &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]),
                0x00,
                IPV6_ADDRESS_LENGTH_IN_BYTES >> 1
        );
    }
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrExtractFromSuffixIeee154AddrExt(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM * ieee154Addr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t MCS51_STORED_IN_RAM *         euiBytePtr;
    uint8_t                               i;

    addrBytePtr = &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]);
    euiBytePtr = &(ieee154Addr->data[(IPV6_ADDRESS_LENGTH_IN_BYTES >> 1) - 1]);
    *euiBytePtr = (*addrBytePtr) ^ 0x02;
    for (i = (IPV6_ADDRESS_LENGTH_IN_BYTES >> 1) - 1; i > 0; --i)
    {
        ++addrBytePtr;
        --euiBytePtr;
        *euiBytePtr = (*addrBytePtr);
    }
}



/**
 * Checks if the 8-byte suffix of a given IPv6 address
 * may be formed from a short IEEE 802.15.4 address and
 * a given PAN identifier.
 * @param ipv6Addr The address to be checked.
 * @param ieee154PanId The PAN identifier.
 * @return Nonzero if the suffix may contain an IEEE
 *   802.15.4 short address or zero otherwise.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_ipv6AddrCheckIfSuffixMayContainIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t MCS51_STORED_IN_RAM const *   panIdBytePtr;

    addrBytePtr = &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]);
    panIdBytePtr = &(ieee154PanId->data[IEEE154_PAN_ID_BYTE_LENGTH - 1]);
    if ((*addrBytePtr) != ((*panIdBytePtr) & ~(uint8_t)0x02))
    {
        return 0;
    }
    ++addrBytePtr;
    --panIdBytePtr;
    if ((*addrBytePtr) != (*panIdBytePtr))
    {
        return 0;
    }
    ++addrBytePtr;
    if ((*addrBytePtr) != 0x00)
    {
        return 0;
    }
    ++addrBytePtr;
    if ((*addrBytePtr) != 0xff)
    {
        return 0;
    }
    ++addrBytePtr;
    if ((*addrBytePtr) != 0xfe)
    {
        return 0;
    }
    ++addrBytePtr;
    if ((*addrBytePtr) != 0x00)
    {
        return 0;
    }
    return 1;
}



/**
 * Extracts from the 8-byte suffix of a given IPv6 address
 * a short IEEE 802.15.4 address.
 * @param ipv6Addr The address to be checked.
 * @param ieee154Addr The IEEE 802.15.4 short address to
 *   extract to.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6AddrJustExtractFromSuffixIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM * ieee154Addr
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM const *   addrBytePtr;
    uint8_t MCS51_STORED_IN_RAM *         idBytePtr;

    addrBytePtr = &(ipv6Addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES - IEEE154_SHORT_ADDR_BYTE_LENGTH]);
    idBytePtr = &(ieee154Addr->data[IEEE154_SHORT_ADDR_BYTE_LENGTH - 1]);
    *idBytePtr = (*addrBytePtr);
    ++addrBytePtr;
    --idBytePtr;
    *idBytePtr = (*addrBytePtr);
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_ipv6AddrExtractFromSuffixIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (! whip6_ipv6AddrCheckIfSuffixMayContainIeee154AddrShort(ipv6Addr, ieee154PanId))
    {
        return 0;
    }
    whip6_ipv6AddrJustExtractFromSuffixIeee154AddrShort(ipv6Addr, ieee154Addr);
    return 1;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_addr_t MCS51_STORED_IN_RAM * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (whip6_ipv6AddrCheckIfSuffixMayContainIeee154AddrShort(ipv6Addr, ieee154PanId))
    {
        ieee154Addr->mode = IEEE154_ADDR_MODE_SHORT;
        whip6_ipv6AddrJustExtractFromSuffixIeee154AddrShort(
                ipv6Addr,
                &(ieee154Addr->vars.shrt)
        );
    }
    else
    {
        ieee154Addr->mode = IEEE154_ADDR_MODE_EXT;
        whip6_ipv6AddrExtractFromSuffixIeee154AddrExt(
                ipv6Addr,
                &(ieee154Addr->vars.ext)
        );
    }
}
