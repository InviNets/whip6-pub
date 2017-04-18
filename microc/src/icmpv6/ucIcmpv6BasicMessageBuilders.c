/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <base/ucIoVec.h>
#include <base/ucString.h>
#include <icmpv6/ucIcmpv6BasicMessageBuilders.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6PacketAllocation.h>



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_icmpv6CreatePacketProtoFillInIpv6Header(
        ipv6_basic_header_t MCS51_STORED_IN_RAM * hdr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    whip6_ipv6BasicHeaderSetVersion(hdr, WHIP6_IPV6_VERSION_NUMBER);
    whip6_ipv6BasicHeaderSetTrafficClass(hdr, 0);
    whip6_ipv6BasicHeaderSetFlowLabel(hdr, 0);
    whip6_ipv6BasicHeaderSetPayloadLength(hdr, packetSize);
    whip6_ipv6BasicHeaderSetNextHeader(hdr, WHIP6_IANA_IPV6_ICMP);
    whip6_ipv6BasicHeaderSetHopLimit(hdr, WHIP6_IPV6_DEFAULT_HOP_LIMIT);
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)srcAddr,
            (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(hdr),
            sizeof(ipv6_addr_t)
    );
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)dstAddr,
            (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(hdr),
            sizeof(ipv6_addr_t)
    );
}



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_icmpv6CreatePacketProtoForCommonFormatMessage(
        ipv6_addr_t MCS51_STORED_IN_RAM const * srcAddr,
        ipv6_addr_t MCS51_STORED_IN_RAM const * dstAddr,
        ipv6_payload_length_t packetSize,
        icmpv6_message_type_t icmpv6Type,
        icmpv6_message_code_t icmpv6Code,
        uint32_t icmpv6RemainingFourOctets,
        iov_blist_iter_t * iovIter
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_packet_t MCS51_STORED_IN_RAM *   packet;
    iov_blist_t MCS51_STORED_IN_RAM *     iovList;
    uint8_t MCS51_STORED_IN_RAM *         payloadPtr;

    packetSize += sizeof(icmpv6_message_header_t) + sizeof(uint32_t);
    packet = whip6_ipv6AllocatePacket(packetSize);
    if (packet == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    whip6_icmpv6CreatePacketProtoFillInIpv6Header(
            &packet->header,
            srcAddr,
            dstAddr,
            packetSize
    );
    iovList = packet->firstPayloadIov;
    // NOTICE iwanicki 2013-06-21:
    // For performance, we do the following check.
    if (iovList->iov.len <
            sizeof(icmpv6_message_header_t) + sizeof(uint32_t))
    {
        goto FAILURE_ROLLBACK_1;
    }
    // NOTICE iwanicki 2013-06-21:
    // Again, for performance, we perform the serialization
    // and iterator initialization manually.
    payloadPtr = iovList->iov.ptr;
    *payloadPtr = icmpv6Type;
    ++payloadPtr;
    *payloadPtr = icmpv6Code;
    ++payloadPtr;
    *payloadPtr = 0;
    ++payloadPtr;
    *payloadPtr = 0;
    ++payloadPtr;
    *payloadPtr = (uint8_t)(icmpv6RemainingFourOctets >> 24);
    ++payloadPtr;
    *payloadPtr = (uint8_t)(icmpv6RemainingFourOctets >> 16);
    ++payloadPtr;
    *payloadPtr = (uint8_t)(icmpv6RemainingFourOctets >> 8);
    ++payloadPtr;
    *payloadPtr = (uint8_t)(icmpv6RemainingFourOctets);
    ++payloadPtr;
    iovIter->currElem = iovList;
    iovIter->offset = sizeof(icmpv6_message_header_t) + sizeof(uint32_t);
    return packet;

FAILURE_ROLLBACK_1:
    whip6_ipv6FreePacket(packet);
FAILURE_ROLLBACK_0:
    return NULL;
}
