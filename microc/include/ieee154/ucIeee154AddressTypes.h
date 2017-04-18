/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_TYPES_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains address type definitions for IEEE 802.15.4.
 * For more information, refer to docs/802.15.4-2003.pdf.
 */

#include <eui/ucEui64Types.h>


enum
{
    /** The number of bytes in an IEEE 802.15.4 PAN identifier. */
    IEEE154_PAN_ID_BYTE_LENGTH = 2,
    /** The number of bytes in an IEEE 802.15.4 short address. */
    IEEE154_SHORT_ADDR_BYTE_LENGTH = 2,
    /** The number of bytes in an IEEE 802.15.4 extended address. */
    IEEE154_EXT_ADDR_BYTE_LENGTH = IEEE_EUI64_BYTE_LENGTH,
};

enum
{
    /** The IEEE 802.15.4 broadcast address. */
    IEEE154_SHORT_BCAST_ADDR = 0xffffU,

    /** Reserved address used to denote that no address is set */
    IEEE154_SHORT_NULL_ADDR = 0xe000U,
};

enum ieee154_addr_mode_e
{
    /** The NONE addressing mode in IEEE 802.15.4. */
    IEEE154_ADDR_MODE_NONE = 0x0,
    /** The SHORT addressing mode in IEEE 802.15.4. */
    IEEE154_ADDR_MODE_SHORT = 0x2,
    /** The EXTENDED addressing mode in IEEE 802.15.4. */
    IEEE154_ADDR_MODE_EXT = 0x3,
};

enum
{
    IEEE154_ADDR_MODE_MASK = 0x3,
};

/**
 * An IEEE 802.15.4 PAN identifier.
 */
typedef struct ieee154_pan_id_s
{
    uint8_t data[IEEE154_PAN_ID_BYTE_LENGTH];
} MICROC_NETWORK_STRUCT ieee154_pan_id_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_pan_id_t)

/**
 * An IEEE 802.15.4 short address.
 */
typedef struct ieee154_short_addr_s
{
    uint8_t data[IEEE154_SHORT_ADDR_BYTE_LENGTH];
} MICROC_NETWORK_STRUCT ieee154_short_addr_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_short_addr_t)


/**
 * An IEEE 802.15.4 extended address.
 */
typedef struct ieee154_ext_addr_s
{
    uint8_t data[IEEE154_EXT_ADDR_BYTE_LENGTH];
} MICROC_NETWORK_STRUCT ieee154_ext_addr_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_ext_addr_t)


/**
 * An IEEE 802.15.4 address variants.
 */
typedef union ieee154_addr_variants_u
{
    ieee154_short_addr_t   shrt;
    ieee154_ext_addr_t     ext;
} MICROC_NETWORK_STRUCT ieee154_addr_variants_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_addr_variants_t)


/**
 * A general IEEE 802.15.4 address.
 */
typedef struct ieee154_addr_s
{
    uint8_t                   mode;
    ieee154_addr_variants_t   vars;
} MICROC_NETWORK_STRUCT ieee154_addr_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(ieee154_addr_t)


#endif /* __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_TYPES_H__ */
