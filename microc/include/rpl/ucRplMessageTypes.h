/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_RPL_RPL_MESSAGE_TYPES_H__
#define __WHIP6_MICROC_RPL_RPL_MESSAGE_TYPES_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains messages and options defined by RPL.
 * For more information, refer to docs/rfc-6550.pdf.
 */

#include <icmpv6/ucIcmpv6BasicTypes.h>
#include <rpl/ucRplBase.h>



enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DIS = 0x00,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DIO = 0x01,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DAO = 0x02,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DAO_ACK = 0x03,
};


enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PAD1 = 0x00,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PADN = 0x01,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_DAG_METRIC_CONTAINER = 0x02,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION = 0x03,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION = 0x04,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_RPL_TARGET = 0x05,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_TRANSIT_INFORMATION = 0x06,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION = 0x07,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION = 0x08,
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_RPL_TARGET_DESCRIPTOR = 0x09,
};

enum
{
    WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_DEFAULT_OPTION_HEADER_LENGTH = 2,
};

/** The base of an RPL DIS message. */
typedef struct rpl_message_base_dis_s
{
    uint8_t   flags;
    uint8_t   reserved;
} MICROC_NETWORK_STRUCT rpl_message_base_dis_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_base_dis_t)

/** The base of an RPL DIO message. */
typedef struct rpl_message_base_dio_s
{
    uint8_t         rplInstanceId;
    uint8_t         versionNumber;
    uint8_t         rank[2];
    uint8_t         groundedAndMopAndPrf;
    uint8_t         dtsn;
    uint8_t         flags;
    uint8_t         reserved;
    rpl_dodag_id_t   dodagId;
} MICROC_NETWORK_STRUCT rpl_message_base_dio_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_base_dio_t)


/** The option type field of an RPL control message option. */
typedef uint8_t   rpl_message_opt_type_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_type_t)


/** The option length field of an RPL control message option. */
typedef uint8_t   rpl_message_opt_length_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_length_t)


/** The DAG Metric Container option for RPL messages. */
/*typedef struct rpl_message_opt_data_dag_metric_container_s
{
} MICROC_NETWORK_STRUCT rpl_message_opt_data_dag_metric_container_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_data_dag_metric_container_t)*/


/** The Route Information option for RPL messages. */
typedef struct rpl_message_opt_data_route_information_s
{
    uint8_t   prefixLen;
    uint8_t   prefixPref;
    uint8_t   routeLifetime[4];
    uint8_t   prefixData[0];
} MICROC_NETWORK_STRUCT rpl_message_opt_data_route_information_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_data_route_information_t)



/** The DODAG Configuration option for RPL messages. */
typedef struct rpl_message_opt_data_dodag_configuration_s
{
    uint8_t   flagsAndAuthAndPcs;
    uint8_t   dioIntDoubl;
    uint8_t   dioIntMin;
    uint8_t   dioRedund;
    uint8_t   maxRankIncrease[2];
    uint8_t   minHopRankIncrease[2];
    uint8_t   ocp[2];
    uint8_t   reserved;
    uint8_t   defLifetime;
    uint8_t   lifetimeUnit[2];
} MICROC_NETWORK_STRUCT rpl_message_opt_data_dodag_configuration_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_data_dodag_configuration_t)



/** The Solicited Information option for RPL messages. */
typedef struct rpl_message_opt_data_solicited_information_s
{
    uint8_t         rplInstanceId;
    uint8_t         vidAndFlags;
    rpl_dodag_id_t   dodagId;
    uint8_t         versionNumber;
} MICROC_NETWORK_STRUCT rpl_message_opt_data_solicited_information_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(rpl_message_opt_data_solicited_information_t)


#endif /* __WHIP6_MICROC_RPL_RPL_MESSAGE_TYPES_H__ */
