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

#ifndef __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_PROCESSING_H__
#define __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_PROCESSING_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains common functions for processing
 * IPv6 extension headers.
 * For more information, refer to docs/rfc2460.pdf.
 */

#include <ipv6/ucIpv6ExtensionHeaderTypes.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>



/**
 * Fetches a generic IPv6 extension header
 * into the scratch-pad of the processing state
 * and skips it. In the case of an error, the
 * state will indicate that the packet should
 * be dropped.
 * @param state The state of an IPv6 packet processor.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6ExtensionHeaderGenericFetchAndSkipHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Creates an ICMPv6 message informing about
 * an unrecognized header (if ICMPv6 messages are not
 * disabled). As a result, the state will indicate
 * that the packet should be dropped.
 * @param state The state of an IPv6 packet processor.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_ipv6ExtensionHeaderGenericHandleUnrecognizedHeaderIncoming(
        ipv6_in_packet_processing_state_t MCS51_STORED_IN_RAM * state
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;




#endif /* __WHIP6_MICROC_IPV6_IPV6_EXTENSION_HEADER_PROCESSING_H__ */
