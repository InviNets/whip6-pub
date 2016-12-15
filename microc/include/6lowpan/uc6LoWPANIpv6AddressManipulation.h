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

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_ADDRESS_MANIPULATION_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_ADDRESS_MANIPULATION_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains 6LoWPAN-specific functionality
 * for manipulating IPv6 addresses.
 */

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6AddressTypes.h>



/**
 * Fills in the 8-byte suffix of a given IPv6 address
 * to contain an appropriately converted IEEE 802.15.4
 * extended address.
 * @param ipv6Addr The IPv6 address to modify.
 * @param ieee154Addr The IEEE 802.15.4 address to
 *   draw from.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrExt(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM const * ieee154Addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Fills in the 8-byte suffix of a given IPv6 address
 * to contain an appropriately converted IEEE 802.15.4
 * short address.
 * @param ipv6Addr The IPv6 address to modify.
 * @param ieee154Addr The IEEE 802.15.4 address to
 *   draw from.
 * @param ieee154PanId The IEEE 802.15.4 PAN identifier.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM const * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Fills in the 8-byte suffix of a given IPv6 address to
 * contain an appropriately converted IEEE 802.15.4 address.
 * @param ipv6Addr The IPv6 address to modify.
 * @param ieee154Addr The IEEE 802.15.4 address to
 *   draw from.
 * @param ieee154PanId The IEEE 802.15.4 PAN identifier.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrFillSuffixWithIeee154AddrAny(
        ipv6_addr_t MCS51_STORED_IN_RAM * ipv6Addr,
        ieee154_addr_t MCS51_STORED_IN_RAM const * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Extracts an extended IEEE 802.15.4 address from
 * the 8-byte suffix of a given IPv6 address.
 * @param ipv6Addr The IPv6 address from which the extraction
 *   will be done.
 * @param ieee154Addr The IEEE 802.15.4 extended address to
 *   extract to.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrExtractFromSuffixIeee154AddrExt(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_ext_addr_t MCS51_STORED_IN_RAM * ieee154Addr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Extracts a short IEEE 802.15.4 address from the 8-byte
 * suffix of a given IPv6 address assuming a given
 * PAN identifier.
 * @param ipv6Addr The IPv6 address from which the extraction
 *   will be done.
 * @param ieee154Addr The IEEE 802.15.4 short address to
 *   extract to.
 * @param ieee154PanId The IEEE 802.15.4 PAN identifier.
 * @return Nonzero on success or zero otherwise, in which case
 *   the contents of the IEEE 802.15.4 short address are
 *   undefined.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX uint8_t whip6_ipv6AddrExtractFromSuffixIeee154AddrShort(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_short_addr_t MCS51_STORED_IN_RAM * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Extracts an IEEE 802.15.4 address (either short or
 * extended) from the 8-byte suffix of a given IPv6
 * address assuming that the communication takes place
 * within a personal area network with a given PAN
 * identifier.
 * @param ipv6Addr The IPv6 address from which the
 *   extraction will be done.
 * @param ieee154Addr The IEEE 802.15.4 address to
 *   extract to.
 * @param ieee154PanId The IEEE 802.15.4 PAN identifier.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
        ipv6_addr_t MCS51_STORED_IN_RAM const * ipv6Addr,
        ieee154_addr_t MCS51_STORED_IN_RAM * ieee154Addr,
        ieee154_pan_id_t MCS51_STORED_IN_RAM const * ieee154PanId
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_IPV6_ADDRESS_MANIPULATION_H__ */
