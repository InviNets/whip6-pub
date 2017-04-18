/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_RPL_RPL_BASE_H__
#define __WHIP6_MICROC_RPL_RPL_BASE_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains basic types for RPL.
 * For more information, refer to docs/rfc-6550.pdf.
 */

#include <base/ucTypes.h>
#include <ipv6/ucIpv6AddressTypes.h>

/**
 * A lollipop counter for RPL.
 */
typedef uint8_t   rpl_lollipop_counter_t;

/**
 * The RPL DODAGID type.
 */
typedef ipv6_addr_t   rpl_dodag_id_t;

/**
 * The RPL RPLInstanceID type.
 */
typedef uint8_t   rpl_instance_id_t;

/**
 * The RPL DODAGVersionNumber type.
 */
typedef rpl_lollipop_counter_t   rpl_dodag_version_t;

/**
 * The RPL Objective Code Point type.
 */
typedef uint16_t   rpl_ocp_t;

/**
 * The RPL Rank type.
 */
typedef uint16_t   rpl_rank_t;

/**
 * The RPL Mode of Operation type.
 */
typedef uint8_t   rpl_mop_t;

enum
{
    WHIP6_RPL_MOP_NO_DOWNWARD_ROUTES = 0x00,
    WHIP6_RPL_MOP_NON_STORING = 0x01,
    WHIP6_RPL_MOP_STORING_WITHOUT_MULTICAST = 0x02,
    WHIP6_RPL_MOP_STORING_WITH_MULTICAST = 0x03,
};

/**
 * The RPL DODAGPreference type.
 */
typedef uint8_t       rpl_dodag_preference_t;

enum
{
    WHIP6_RPL_DODAG_PREFERENCE_LOWEST = 0x00,
    WHIP6_RPL_DODAG_PREFERENCE_VERY_LOW = 0x01,
    WHIP6_RPL_DODAG_PREFERENCE_LOW = 0x02,
    WHIP6_RPL_DODAG_PREFERENCE_MEDIUM_LOW = 0x03,
    WHIP6_RPL_DODAG_PREFERENCE_MEDIUM_HIGH = 0x04,
    WHIP6_RPL_DODAG_PREFERENCE_HIGH = 0x05,
    WHIP6_RPL_DODAG_PREFERENCE_VERY_HIGH = 0x06,
    WHIP6_RPL_DODAG_PREFERENCE_HIGHEST = 0x07,
};

/**
 * The RPL Destination Advertisement Trigger Sequence Number type.
 */
typedef rpl_lollipop_counter_t   rpl_dest_advert_trigger_seq_no_t;

/**
 * The RPL Path Control Size type.
 */
typedef uint8_t   rpl_path_control_size_t;

/**
 * The RPL Interval Doublings type.
 */
typedef uint8_t   rpl_interval_doublings_t;

/**
 * The RPL Interval Redundancy type.
 */
typedef uint8_t   rpl_interval_redundancy_t;


#endif /* __WHIP6_MICROC_RPL_RPL_BASE_H__ */
