/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_ICMPV6_ICMPV6_CONSTANTS_H__
#define __WHIP6_MICROC_ICMPV6_ICMPV6_CONSTANTS_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains constants for
 * ICMPv6 messages.
 * For more information, see docs/rfc4443.pdf
 */

enum
{
    ICMPV6_MESSAGE_TYPE_ECHO_REQUEST = 128,
    ICMPV6_MESSAGE_TYPE_ECHO_REPLY = 129,
};


#endif /* __WHIP6_MICROC_ICMPV6_ICMPV6_CONSTANTS_H__ */
