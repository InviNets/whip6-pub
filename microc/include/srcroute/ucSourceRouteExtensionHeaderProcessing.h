/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_PROCESSING_H__
#define __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_PROCESSING_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains functions for processing
 * an IPv6 extension header that allows for source
 * routing in combination with RPL.
 * For more information, refer to docs/rfc6554.pdf.
 */

#include <srcroute/ucSourceRouteExtensionHeaderManipulation.h>
#include <srcroute/ucSourceRouteExtensionHeaderTypes.h>


/**
 * Fetches an IPv6 source route extension header
 * into the scratch-pad of the processing state.
 * In the case of an error, the state will indicate
 * that the packet should be dropped.
 * @param state The state of an IPv6 packet processor.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteFetchHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Processes an IPv6 source route extension header
 * and modifies the processing state (and the packet
 * if necessary) accordingly.
 * @param state The state of an IPv6 packet processor.
 *   The iterator in the state should point at the first
 *   byte of the extension header. If this function
 *   succeeds, the iterator will point at the first
 *   byte of the following header.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6ExtensionHeaderSourceRouteProcessHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;



#endif /* __WHIP6_MICROC_SRCROUTE_SOURCE_ROUTE_EXTENSION_HEADER_PROCESSING_H__ */
