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

#ifndef __WHIP6_MICROC_IPV6_IPV6_IANA_CONSTANTS_H__
#define __WHIP6_MICROC_IPV6_IPV6_IANA_CONSTANTS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains global IANA constants.
 *
 */

enum
{
    WHIP6_IPV6_VERSION_NUMBER = 6,
    WHIP6_IPV6_DEFAULT_HOP_LIMIT = 64,
};

enum
{
    WHIP6_IPV6_MIN_MTU = 1280,
};


enum whip6_iana_constants_e
{
    /** Hop-by-hop options for IPv6. */
    WHIP6_IANA_IPV6_HOP_BY_HOP_OPTIONS = 0,
    /** User Datagram Protocol (UDP). */
    WHIP6_IANA_IPV6_UDP = 17,
    /** Routing header for IPv6. */
    WHIP6_IANA_IPV6_ROUTING = 43,
    /** Fragmentation header for IPv6. */
    WHIP6_IANA_IPV6_FRAGMENTATION = 44,
    /** ICMPv6. */
    WHIP6_IANA_IPV6_ICMP = 58,
    /** No next header. */
    WHIP6_IANA_IPV6_NO_NEXT_HEADER = 59,
    /** Destination options for IPv6. */
    WHIP6_IANA_IPV6_DESTINATION_OPTIONS = 60,
};

#endif /* __WHIP6_MICROC_IPV6_IPV6_IANA_CONSTANTS_H__ */
