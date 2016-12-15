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
#include <base/ucIoVec.h>
#include <base/ucString.h>
#include <external/ucExternalIpv6Allocators.h>
#include <icmpv6/ucIcmpv6BasicMessageProcessing.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6WrapDataIntoOutgoingIpv6PacketCarryingIcmpMessage(
        iov_blist_iter_t MCS51_STORED_IN_RAM * payloadIter,
        size_t payloadLen,
        icmpv6_message_header_t MCS51_STORED_IN_RAM * icmpv6HdrPtr,
        iov_blist_t MCS51_STORED_IN_RAM * icmpv6HdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * firstIov,
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddrOrNull,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_packet_t MCS51_STORED_IN_RAM *         packet;
    iov_blist_t MCS51_STORED_IN_RAM *           prevIov;
    iov_blist_t MCS51_STORED_IN_RAM *           currIov;
    ipv6_basic_header_t MCS51_STORED_IN_RAM *   ipv6Hdr;

    icmpv6HdrIov->iov.ptr = (uint8_t MCS51_STORED_IN_RAM *)icmpv6HdrPtr;
    icmpv6HdrIov->iov.len = sizeof(icmpv6_message_header_t);
    icmpv6HdrIov->prev = NULL;
    currIov = payloadIter->currElem;
    if (currIov != NULL && payloadLen > 0)
    {
        size_t   maxPayload;

        icmpv6HdrIov->next = firstIov;
        firstIov->iov.ptr = currIov->iov.ptr + payloadIter->offset;
        firstIov->iov.len = currIov->iov.len - payloadIter->offset;
        firstIov->next = currIov->next;
        if (firstIov->next != NULL)
        {
            firstIov->next->prev = firstIov;
        }
        firstIov->prev = icmpv6HdrIov;
        payloadLen += sizeof(icmpv6_message_header_t);
        maxPayload = 0;
        currIov = icmpv6HdrIov;
        prevIov = NULL;
        while (currIov != NULL)
        {
            maxPayload += currIov->iov.len;
            prevIov = currIov;
            currIov = currIov->next;
        }
        if (maxPayload < payloadLen)
        {
            goto FAILURE_ROLLBACK_1;
        }
    }
    else
    {
        if (payloadLen > 0)
        {
            goto FAILURE_ROLLBACK_0;
        }
        icmpv6HdrIov->next = NULL;
        payloadLen = sizeof(icmpv6_message_header_t);
        prevIov = icmpv6HdrIov;
    }
    packet = whip6_ipv6AllocNewIPv6Packet();
    if (packet == NULL)
    {
        goto FAILURE_ROLLBACK_1;
    }
    packet->firstPayloadIov = icmpv6HdrIov;
    packet->lastPayloadIov = prevIov;
    ipv6Hdr = &packet->header;
    whip6_ipv6BasicHeaderSetVersion(ipv6Hdr, WHIP6_IPV6_VERSION_NUMBER);
    whip6_ipv6BasicHeaderSetTrafficClass(ipv6Hdr, 0);
    whip6_ipv6BasicHeaderSetFlowLabel(ipv6Hdr, 0);
    whip6_ipv6BasicHeaderSetPayloadLength(ipv6Hdr, payloadLen);
    whip6_ipv6BasicHeaderSetNextHeader(ipv6Hdr, WHIP6_IANA_IPV6_ICMP);
    if (srcAddrOrNull == NULL)
    {
        whip6_ipv6AddrSetUndefinedAddr(whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(ipv6Hdr));
    }
    else
    {
        whip6_shortMemCpy(
                (uint8_t MCS51_STORED_IN_RAM const *)srcAddrOrNull,
                (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(ipv6Hdr),
                sizeof(ipv6_addr_t)
        );
    }
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)dstAddr,
            (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(ipv6Hdr),
            sizeof(ipv6_addr_t)
    );
    if (whip6_ipv6AddrGetScope(dstAddr) <= IPV6_ADDRESS_SCOPE_LINK_LOCAL)
    {
        whip6_ipv6BasicHeaderSetHopLimit(ipv6Hdr, 1);
    }
    else
    {
        whip6_ipv6BasicHeaderSetHopLimit(ipv6Hdr, WHIP6_IPV6_DEFAULT_HOP_LIMIT);
    }
    return packet;

// FAILURE_ROLLBACK_2:
//    whip6_ipv6FreeExistingIPv6Packet(packet);
FAILURE_ROLLBACK_1:
    currIov = payloadIter->currElem;
    if (currIov != NULL)
    {
        if (currIov->next != NULL)
        {
            currIov->next->prev = currIov;
        }
    }
FAILURE_ROLLBACK_0:
    return NULL;

}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_icmpv6UnwrapDataFromOutgoingIpv6PacketCarryingIcmpMessage(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        iov_blist_iter_t MCS51_STORED_IN_RAM * payloadIter,
        size_t payloadLen,
        iov_blist_t MCS51_STORED_IN_RAM * icmpv6HdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * firstIov
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    if (packet == NULL || payloadIter == NULL ||
            icmpv6HdrIov == NULL || firstIov == NULL)
    {
        return 1;
    }
    if (payloadLen + sizeof(icmpv6_message_header_t) !=
                (size_t)whip6_ipv6BasicHeaderGetPayloadLength(&packet->header) ||
            whip6_ipv6BasicHeaderGetNextHeader(&packet->header) != WHIP6_IANA_IPV6_ICMP ||
            packet->firstPayloadIov != icmpv6HdrIov ||
            icmpv6HdrIov->iov.len != sizeof(icmpv6_message_header_t))
    {
        return 1;
    }
    if (payloadLen == 0)
    {
        if (packet->firstPayloadIov->next != NULL)
        {
            return 1;
        }
    }
    else
    {
        if (payloadIter->currElem == NULL ||
                packet->firstPayloadIov->next != firstIov)
        {
            return 1;
        }
        if (payloadIter->currElem->next != firstIov->next)
        {
            return 1;
        }
    }
    icmpv6HdrIov->next = NULL;
    icmpv6HdrIov->prev = NULL;
    firstIov->next = NULL;
    firstIov->prev = NULL;
    firstIov = payloadIter->currElem;
    if (firstIov != NULL)
    {
        if (firstIov->next != NULL)
        {
            firstIov->next->prev = firstIov;
        }
    }
    whip6_ipv6FreeExistingIPv6Packet(packet);
    return 0;
}
