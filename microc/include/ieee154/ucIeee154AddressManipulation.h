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

#ifndef __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_MANIPULATION_H__
#define __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains address manipulation functions
 * for IEEE 802.15.4.
 */

#include <ieee154/ucIeee154AddressTypes.h>

/**
 * Copies an IEEE 802.15.4 short address from
 * one place to another. It is assumed that
 * the addresses do not overlap in memory.
 * @param srcAddr The source address.
 * @param dstAddr The destination address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrShortCpy(
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Copies an IEEE 802.15.4 extended address from
 * one place to another. It is assumed that
 * the addresses do not overlap in memory.
 * @param srcAddr The source address.
 * @param dstAddr The destination address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrExtCpy(
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Copies any IEEE 802.15.4 address from
 * one place to another. It is assumed that
 * the addresses do not overlap in memory.
 * @param srcAddr The source address.
 * @param dstAddr The destination address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrAnyCpy(
        ieee154_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ieee154_addr_t MCS51_STORED_IN_RAM * dstAddr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Compares two short IEEE 802.15.4 address.
 * @param addr1 The first address.
 * @param addr2 The second address.
 * @return A negative value if the first address
 *   is lexicographically earlier than the second;
 *   a positive value if the first address
 *   is lexicographically later than the second;
 *   zero if the addresses are equal.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_ieee154AddrShortCmp(
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Compares two extended IEEE 802.15.4 address.
 * @param addr1 The first address.
 * @param addr2 The second address.
 * @return A negative value if the first address
 *   is lexicographically earlier than the second;
 *   a positive value if the first address
 *   is lexicographically later than the second;
 *   zero if the addresses are equal.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_ieee154AddrExtCmp(
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Compares two IEEE 802.15.4 address.
 * @param addr1 The first address.
 * @param addr2 The second address.
 * @return A negative value if the first address
 *   is lexicographically earlier than the second;
 *   a positive value if the first address
 *   is lexicographically later than the second;
 *   zero if the addresses are equal.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX int8_t whip6_ieee154AddrAnyCmp(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr1,
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr2
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Compares IEEE 802.15.4 addres to a short addres passed
 * by value.
 * @param addr1 The first address.
 * @param addr2Value Integer describing the short address.
 * @return TRUE is addr1 is a short address with 16 bit value
 *   eqal to addr2Value. Otherwise return FALSE.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_ieee154AddrAnyEqShrt(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr1,
        uint16_t addr2Value
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets a given IEEE 802.15.4 address
 * to a SHRT address.
 * @param addr The address to be set.
 * @param addrValue The 16 bit value of the address.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrAnySetShrt(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr,
        uint16_t addrValue
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets a given IEEE 802.15.4 address
 * to a NONE address.
 * @param addr The address to be set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrAnySetNone(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Sets a given IEEE 802.15.4 address
 * to a broadcast address.
 * @param addr The address to be set.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154AddrAnySetBroadcast(
        ieee154_addr_t MCS51_STORED_IN_RAM * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IEEE 802.15.4 address
 * is a NONE address.
 * @param addr The address to be checked.
 * @return Nonzero if the given address is
 *   a NONE address or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ieee154AddrAnyIsNone(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Checks if a given IEEE 802.15.4 address
 * is a broadcast address.
 * @param addr The address to be checked.
 * @return Nonzero if the given address is
 *   a broadcast address or zero otherwise.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_ieee154AddrAnyIsBroadcast(
        ieee154_addr_t MCS51_STORED_IN_RAM const * addr
) WHIP6_MICROC_INLINE_DECL_SUFFIX;


/**
 * Copies an IEEE 802.15.4 PAN ID from one
 * place to another. It is assumed that
 * the PAN IDs do not overlap in memory.
 * @param srcPanId The source PAN ID.
 * @param dstPanId The destination PAN ID.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX void whip6_ieee154PanIdCpy(
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * srcPanId,
        ieee154_pan_id_t MCS51_STORED_IN_RAM * dstPanId
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Compares two IEEE 802.15.4 PAN IDs.
 * @param panId1 The first PAN ID.
 * @param panId2 The second PAN ID.
 * @return A negative value if the first ID
 *   is lexicographically earlier than the second;
 *   a positive value if the first ID
 *   is lexicographically later than the second;
 *   zero if the IDs are equal.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX int8_t whip6_ieee154PanIdCmp(
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId1,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * panId2
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

#include <ieee154/detail/ucIeee154AddressManipulationImpl.h>

#endif /* __WHIP6_MICROC_IEEE154_IEEE154_ADDRESS_MANIPULATION_H__ */
