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

#ifndef __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_TYPES_H__
#define __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains type definitions for
 * ICMPv6 messages.
 * For more information, see docs/rfc4443.pdf
 */

#include <ipv6/ucIpv6BasicHeaderTypes.h>



/** The type field in ICMPv6 messages. */
typedef uint8_t icmpv6_message_type_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_type_t)

/** The code field in ICMPv6 messages. */
typedef uint8_t icmpv6_message_code_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_code_t)

/** The pointer field in ICMPv6 parameter problem messages. */
typedef uint32_t icmpv6_message_parameter_problem_pointer_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_parameter_problem_pointer_t)

/** The identifier field in ICMPv6 echo messages. */
typedef uint16_t icmpv6_message_parameter_echo_identifier_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_parameter_echo_identifier_t)

/** The sequence number field in ICMPv6 echo messages. */
typedef uint16_t icmpv6_message_parameter_echo_seq_no_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_parameter_echo_seq_no_t)


/** An ICMPv6 message header. */
typedef struct icmpv6_message_header_s
{
    uint8_t       type;
    uint8_t       code;
    uint8_t       checksum[2];
} MICROC_NETWORK_STRUCT icmpv6_message_header_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(icmpv6_message_header_t)



enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_DESTINATION_UNREACHABLE = 1,
    WHIP6_ICMPV6_MESSAGE_TYPE_PACKET_TOO_BIG = 2,
    WHIP6_ICMPV6_MESSAGE_TYPE_TIME_EXCEEDED = 3,
    WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM = 4,
    WHIP6_ICMPV6_MESSAGE_TYPE_ECHO_REQUEST = 128,
    WHIP6_ICMPV6_MESSAGE_TYPE_ECHO_REPLY = 129,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE = 155,
};

enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_TIME_EXCEEDED_CODE_HOP_LIMIT_EXCEEDED = 0,
    WHIP6_ICMPV6_MESSAGE_TYPE_TIME_EXCEEDED_CODE_FRAGMENT_REASSEMBLY_TIME_EXCEEDED = 1,
};

enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_ERRONEOUS_HEADER_FIELD = 0,
    WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_UNRECOGNIZED_NEXT_HEADER_TYPE = 1,
    WHIP6_ICMPV6_MESSAGE_TYPE_PARAMETER_PROBLEM_CODE_UNRECOGNIZED_IPV6_OPTION = 2,
};

#endif /* __WHIP6_MICROC_ICMPV6_ICMPV6_BASIC_TYPES_H__ */
