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

#include <rpl/ucRplMessageBuilders.h>


enum
{
    WHIP6_RPL_CONTROL_MESSAGE_DIO_GROUNDED_FLAG = (1 << 7),
    WHIP6_RPL_CONTROL_MESSAGE_DIO_MOP_MASK = 0x7,
    WHIP6_RPL_CONTROL_MESSAGE_DIO_MOP_SHIFT = 3,
    WHIP6_RPL_CONTROL_MESSAGE_DIO_PRF_MASK = 0x7,
    WHIP6_RPL_CONTROL_MESSAGE_DIO_PRF_SHIFT = 0,
};

enum
{
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_OPTION_LENGTH = 19,

    WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_VERSION = (1 << 7),
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_INSTANCE = (1 << 6),
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_DODAGID = (1 << 5),
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_UNDEFINED_FLAGS_MASK =
            WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_DODAGID - 1,
};

enum
{
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION_PREFERENCE_MASK = IPV6_ROUTER_PREFERENCE_MASK,
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION_PREFERENCE_SHIFT = 3,
};

enum
{
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_OPTION_LENGTH = 14,

    WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_PCS_MASK = 0x7,
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_PCS_SHIFT = 0,
};



enum
{
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_OPTION_LENGTH = 30,

    WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_ON_LINK = (1 << 7),
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_AAC = (1 << 6),
    WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_ROUTER_ADDR = (1 << 5),
};


#define whip6_icmpv6RplAdvanceIovIterByOne(iovO, iovP, np) \
    do \
    { \
        ++(iovP); \
        ++(iovO); \
        ++(np); \
    } \
    while (0);

#define whip6_icmpv6RplFinishAdvancingIovIter(iovE, iovO, iovL) \
    do \
    { \
        if ((iovO) >= (iovL)) \
        { \
            (iovE) = (iovE)->next; \
            (iovO) = 0; \
        } \
    } \
    while (0);


#define whip6_icmpv6RplCheckIovIterAfterAdvance(iovE, iovO, iovP, iovL, lab) \
    do \
    { \
        if ((iovO) >= (iovL)) \
        { \
            (iovE) = (iovE)->next; \
            if ((iovE) == NULL) \
            { \
                goto lab; \
            } \
            (iovO) = 0; \
            (iovP) = (iovE)->iov.ptr; \
            (iovL) = (iovE)->iov.len; \
        } \
    } \
    while (0);



/**
 * Stores an address prefix in a message.
 * @param iovIter An iterator over the message.
 * @param prefixData A buffer with the prefix.
 * @param prefixLengthInBits The length of the
 *   prefix in bits.
 * @param bytesToStore The maximal number of bytes
 *   to store.
 * @return The number of bytes remaining to be stored.
 */
WHIP6_MICROC_PRIVATE_DEF_PREFIX uint8_t whip6_icmpv6RplStoreAddressPrefixInMessage(
        iov_blist_iter_t * iovIterOrg,
        uint8_t MCS51_STORED_IN_RAM const * prefixData,
        uint8_t prefixLengthInBits,
        uint8_t bytesToStore
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             realBytesToStore;
    uint8_t                             lastByteMask;
    uint8_t                             numProcessed;

    realBytesToStore = ((prefixLengthInBits + 7) >> 3);
    numProcessed = (prefixLengthInBits & 0x07);
    if (numProcessed == 0)
    {
        lastByteMask = 0xff;
    }
    else
    {
        lastByteMask = (0xff << (8 - numProcessed));
    }
    if (realBytesToStore > bytesToStore)
    {
        lastByteMask = 0xff;
        realBytesToStore = bytesToStore;
    }
    numProcessed = 0;
    iovCurrElem = iovIterOrg->currElem;
    iovOffset = iovIterOrg->offset;
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (realBytesToStore > 0)
    {
        for (--realBytesToStore; realBytesToStore > 0; --realBytesToStore)
        {
            *iovBufPtr = *prefixData;
            ++prefixData;
            whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
            whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        }
        *iovBufPtr = ((*prefixData) & lastByteMask);
        whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    }
    for (realBytesToStore = bytesToStore - realBytesToStore; realBytesToStore > 0; --realBytesToStore)
    {
        whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        *iovBufPtr = 0x00;
        whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    }
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);
    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, iovIterOrg);
    return 0;

FAILURE_ROLLBACK_0:
    return bytesToStore - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplStartBuildingDisMessage(
        rpl_message_builder_t * builder,
        iov_blist_iter_t const * iovIterOrg,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;

    numProcessed = 0;
    iovCurrElem = iovIterOrg->currElem;
    iovOffset = iovIterOrg->offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // ICMPv6 header.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DIS;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);

    // DIS base.
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    builder->packet = packet;
    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return (sizeof(icmpv6_message_header_t) +
            sizeof(rpl_message_base_dis_t)) - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplStartBuildingDioMessage(
        rpl_message_builder_t * builder,
        iov_blist_iter_t const * iovIterOrg,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        rpl_dodag_id_t MCS51_STORED_IN_RAM const * dodagId,
        rpl_dodag_version_t dodagVerNo,
        rpl_instance_id_t rplInstanceId,
        rpl_rank_t rank,
        uint8_t grounded,
        rpl_mop_t mop,
        rpl_dodag_preference_t prf,
        rpl_dest_advert_trigger_seq_no_t dtsn
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *         iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *     iovCurrElem;
    size_t                                iovBufLen;
    size_t                                iovOffset;
    uint8_t                               numProcessed;
    uint8_t                               tmpByte;
    uint8_t MCS51_STORED_IN_RAM const *   dodagIdPtr;

    numProcessed = 0;
    iovCurrElem = iovIterOrg->currElem;
    iovOffset = iovIterOrg->offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // ICMPv6 header.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_CODE_DIO;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);

    // DIO base.
    *iovBufPtr = (uint8_t)rplInstanceId;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)dodagVerNo;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(rank >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(rank);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    tmpByte = 0;
    if (grounded)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_DIO_GROUNDED_FLAG;
    }
    tmpByte |= (mop & WHIP6_RPL_CONTROL_MESSAGE_DIO_MOP_MASK) << WHIP6_RPL_CONTROL_MESSAGE_DIO_MOP_SHIFT;
    tmpByte |= (prf & WHIP6_RPL_CONTROL_MESSAGE_DIO_PRF_MASK) << WHIP6_RPL_CONTROL_MESSAGE_DIO_PRF_SHIFT;
    *iovBufPtr = tmpByte;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)dtsn;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    dodagIdPtr = &(dodagId->data8[0]);
    for (tmpByte = sizeof(rpl_dodag_id_t) - 1; tmpByte > 0; --tmpByte)
    {
        *iovBufPtr = *dodagIdPtr;
        ++dodagIdPtr;
        whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
        whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    }
    *iovBufPtr = *dodagIdPtr;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    builder->packet = packet;
    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return (sizeof(icmpv6_message_header_t) +
            sizeof(rpl_message_base_dio_t)) - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPad1(
        rpl_message_builder_t * builder
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PAD1;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return 1 - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPadN(
        rpl_message_builder_t * builder,
        uint8_t numBytes
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;
    uint8_t                             i;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PADN;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr = numBytes;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    if (numBytes == 0)
    {
        whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);
    }
    else
    {
        whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        // Padding.
        for (i = numBytes - 1; i > 0; --i)
        {
            *iovBufPtr = 0x00;
            whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
            whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        }
        *iovBufPtr = 0x00;
        whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
        whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);
    }

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return numBytes + 2 - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionDagMetricContainer(
        rpl_message_builder_t * builder,
        uint8_t MCS51_STORED_IN_RAM const * metricDataPtr,
        uint8_t metricDataLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_DAG_METRIC_CONTAINER;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr = metricDataLen;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Metric data.
    for (--metricDataLen; metricDataLen > 0; --metricDataLen)
    {
        *iovBufPtr = *metricDataPtr;
        ++metricDataPtr;
        whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
        whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    }
    *iovBufPtr = *metricDataPtr;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return (metricDataLen + 2) - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionRouteInformation(
        rpl_message_builder_t * builder,
        uint8_t MCS51_STORED_IN_RAM const * prefixPtr,
        uint32_t routeLiefetimeInSecs,
        uint8_t prefixLen,
        ipv6_router_preference_t routePreference
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;
    uint8_t                             tmpByte;

    numProcessed = 0;
    tmpByte = ((prefixLen + 7) >> 3);
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr =
            sizeof(rpl_message_opt_data_route_information_t) + tmpByte;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Prefix Length.
    *iovBufPtr = prefixLen;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Router preference.
    *iovBufPtr =
            ((routePreference & WHIP6_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION_PREFERENCE_MASK) <<
                    WHIP6_RPL_CONTROL_MESSAGE_OPTION_ROUTE_INFORMATION_PREFERENCE_SHIFT);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Route Lifetime.
    *iovBufPtr = (uint8_t)(routeLiefetimeInSecs >> 24);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(routeLiefetimeInSecs >> 16);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(routeLiefetimeInSecs >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(routeLiefetimeInSecs);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    // Prefix (Variable length)
    return whip6_icmpv6RplStoreAddressPrefixInMessage(
            &builder->iovIter,
            prefixPtr,
            prefixLen,
            tmpByte
    );

FAILURE_ROLLBACK_0:
    return (sizeof(rpl_message_opt_data_route_information_t) + 2) + tmpByte - numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionDodagConfiguration(
        rpl_message_builder_t * builder,
        rpl_path_control_size_t pcs,
        rpl_interval_doublings_t dioIntDoubl,
        rpl_interval_doublings_t dioIntMin,
        rpl_interval_redundancy_t dioRedund,
        rpl_rank_t maxRankIncrease,
        rpl_rank_t minHopRankIncrease,
        rpl_ocp_t ocp,
        uint8_t defLifetime,
        uint16_t lifetimeUnit
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr = WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_OPTION_LENGTH;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Flags & Auth & PCS.
    *iovBufPtr =
            (((uint8_t)pcs & WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_PCS_MASK) <<
                    WHIP6_RPL_CONTROL_MESSAGE_OPTION_DODAG_CONFIGURATION_PCS_SHIFT);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // DIOIntDoubl.
    *iovBufPtr = (uint8_t)dioIntDoubl;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // DIOIntMin.
    *iovBufPtr = (uint8_t)dioIntMin;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // DIORedun.
    *iovBufPtr = (uint8_t)dioRedund;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // MaxRankIncrease.
    *iovBufPtr = (uint8_t)(maxRankIncrease >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(maxRankIncrease);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // MinHopRankIncrease.
    *iovBufPtr = (uint8_t)(minHopRankIncrease >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(minHopRankIncrease);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // OCP.
    *iovBufPtr = (uint8_t)(ocp >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(ocp);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Reserved.
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Def. Lifetime.
    *iovBufPtr = (uint8_t)defLifetime;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Lifetime Unit.
    *iovBufPtr = (uint8_t)(lifetimeUnit >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(lifetimeUnit);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return (sizeof(rpl_message_opt_data_dodag_configuration_t) + 2) - numProcessed;

}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionSolicitedInformation(
        rpl_message_builder_t * builder,
        rpl_dodag_id_t MCS51_STORED_IN_RAM const * dodagId,
        rpl_instance_id_t rplInstanceId,
        rpl_dodag_version_t dodagVerNo,
        uint8_t rplInstanceIdPresent,
        uint8_t dodagVerNoPresent
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;
    uint8_t                             tmpByte;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr = WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_OPTION_LENGTH;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // RPLInstanceId.
    *iovBufPtr = rplInstanceIdPresent ? (uint8_t)rplInstanceId : 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // VID & Flags.
    tmpByte = 0;
    if (rplInstanceIdPresent)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_INSTANCE;
    }
    if (dodagVerNoPresent)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_VERSION;
    }
    if (dodagId != NULL)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_FLAG_DODAGID;
    }
    *iovBufPtr = tmpByte;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // DODAGID.
    if (dodagId != NULL)
    {
        uint8_t MCS51_STORED_IN_RAM const *   dodagIdPtr;
        dodagIdPtr = &(dodagId->data8[0]);
        for (tmpByte = sizeof(rpl_dodag_id_t); tmpByte > 0; --tmpByte)
        {
            *iovBufPtr = *dodagIdPtr;
            ++dodagIdPtr;
            whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
            whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        }
    }
    else
    {
        for (tmpByte = sizeof(rpl_dodag_id_t); tmpByte > 0; --tmpByte)
        {
            *iovBufPtr = 0x00;
            whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
            whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
        }
    }
    // Version Number.
    *iovBufPtr = dodagVerNoPresent ? (uint8_t)dodagVerNo : 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplFinishAdvancingIovIter(iovCurrElem, iovOffset, iovBufLen);

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    return 0;

FAILURE_ROLLBACK_0:
    return (WHIP6_RPL_CONTROL_MESSAGE_OPTION_SOLICITED_INFORMATION_OPTION_LENGTH + 2) -
            numProcessed;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_payload_length_t whip6_icmpv6RplContinueBuildingMessageByAddingOptionPrefixInformation(
        rpl_message_builder_t * builder,
        uint8_t prefixLen,
        uint8_t onLink,
        uint8_t autonomousAddrConf,
        uint8_t router,
        uint32_t validLifetime,
        uint32_t preferredLifetime,
        uint8_t MCS51_STORED_IN_RAM const * prefixPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    uint8_t MCS51_STORED_IN_RAM *       iovBufPtr;
    iov_blist_t MCS51_STORED_IN_RAM *   iovCurrElem;
    size_t                              iovBufLen;
    size_t                              iovOffset;
    uint8_t                             numProcessed;
    uint8_t                             tmpByte;

    numProcessed = 0;
    iovCurrElem = builder->iovIter.currElem;
    iovOffset = builder->iovIter.offset;
    if (iovCurrElem == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    iovBufPtr = iovCurrElem->iov.ptr + iovOffset;
    iovBufLen = iovCurrElem->iov.len;
    if (iovOffset >= iovBufLen)
    {
        goto FAILURE_ROLLBACK_0;
    }

    // Type.
    *iovBufPtr = WHIP6_ICMPV6_MESSAGE_TYPE_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Opt Length.
    *iovBufPtr = WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_OPTION_LENGTH;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Prefix Length.
    *iovBufPtr = prefixLen;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // L & A & R.
    tmpByte = 0;
    if (onLink)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_ON_LINK;
    }
    if (autonomousAddrConf)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_AAC;
    }
    if (router)
    {
        tmpByte |= WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_FLAG_ROUTER_ADDR;
    }
    *iovBufPtr = tmpByte;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Valid Lifetime.
    *iovBufPtr = (uint8_t)(validLifetime >> 24);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(validLifetime >> 16);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(validLifetime >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(validLifetime);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Preferred Lifetime.
    *iovBufPtr = (uint8_t)(preferredLifetime >> 24);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(preferredLifetime >> 16);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(preferredLifetime >> 8);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = (uint8_t)(preferredLifetime);
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    // Reserved2.
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);
    *iovBufPtr = 0x00;
    whip6_icmpv6RplAdvanceIovIterByOne(iovOffset, iovBufPtr, numProcessed);
    whip6_icmpv6RplCheckIovIterAfterAdvance(iovCurrElem, iovOffset, iovBufPtr, iovBufLen, FAILURE_ROLLBACK_0);

    whip6_iovIteratorInitToArbitrary(iovCurrElem, iovOffset, &builder->iovIter);
    // Prefix (Variable length)
    return whip6_icmpv6RplStoreAddressPrefixInMessage(
            &builder->iovIter,
            prefixPtr,
            prefixLen,
            sizeof(ipv6_addr_t)
    );

FAILURE_ROLLBACK_0:
    return (WHIP6_RPL_CONTROL_MESSAGE_OPTION_PREFIX_INFORMATION_OPTION_LENGTH + 2) -
            numProcessed;
}
