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
#include <external/ucExternalIpv6Allocators.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6PacketTypes.h>
#include <udp/ucUdpHeaderManipulation.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_udpWrapDataIntoOutgoingIpv6PacketCarryingUdpDatagram(
        iov_blist_t MCS51_STORED_IN_RAM * payloadIov,
        size_t payloadLen,
        iov_blist_t MCS51_STORED_IN_RAM * udpHdrIov,
        udp_socket_addr_t MCS51_STORED_IN_RAM const * srcSockAddr,
        udp_socket_addr_t MCS51_STORED_IN_RAM const * dstSockAddr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    ipv6_packet_t MCS51_STORED_IN_RAM *         packet;
    iov_blist_t MCS51_STORED_IN_RAM *           currIov;
    iov_blist_t MCS51_STORED_IN_RAM *           prevIov;
    size_t                                      maxPayload;
    ipv6_basic_header_t MCS51_STORED_IN_RAM *   ipv6Hdr;
    uint8_t MCS51_STORED_IN_RAM *               udpHdrRawPtr;
    uint16_t                                    tmp;

    if (udpHdrIov->iov.len != sizeof(udp_header_t))
    {
        goto FAILURE_ROLLBACK_0;
    }
    currIov = payloadIov;
    prevIov = NULL;
    maxPayload = 0;
    while (currIov != NULL)
    {
        maxPayload += currIov->iov.len;
        prevIov = currIov;
        currIov = currIov->next;
    }
    if (maxPayload < payloadLen)
    {
        goto FAILURE_ROLLBACK_0;
    }
    packet = whip6_ipv6AllocNewIPv6Packet();
    if (packet == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    packet->firstPayloadIov = udpHdrIov;
    packet->lastPayloadIov = prevIov;
    if (payloadIov != NULL)
    {
        if (payloadIov->prev != NULL)
        {
            goto FAILURE_ROLLBACK_1;
        }
        payloadIov->prev = udpHdrIov;
    }
    else
    {
        packet->lastPayloadIov = udpHdrIov;
    }
    udpHdrIov->next = payloadIov;
    udpHdrIov->prev = NULL;
    payloadLen += sizeof(udp_header_t);

    ipv6Hdr = &packet->header;
    whip6_ipv6BasicHeaderSetVersion(ipv6Hdr, WHIP6_IPV6_VERSION_NUMBER);
    whip6_ipv6BasicHeaderSetTrafficClass(ipv6Hdr, 0);
    whip6_ipv6BasicHeaderSetFlowLabel(ipv6Hdr, 0);
    whip6_ipv6BasicHeaderSetPayloadLength(ipv6Hdr, payloadLen);
    whip6_ipv6BasicHeaderSetNextHeader(ipv6Hdr, WHIP6_IANA_IPV6_UDP);
    whip6_ipv6BasicHeaderSetHopLimit(ipv6Hdr, WHIP6_IPV6_DEFAULT_HOP_LIMIT);
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)&srcSockAddr->ipv6Addr,
            (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(ipv6Hdr),
            sizeof(ipv6_addr_t)
    );
    whip6_shortMemCpy(
            (uint8_t MCS51_STORED_IN_RAM const *)&dstSockAddr->ipv6Addr,
            (uint8_t MCS51_STORED_IN_RAM *)whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(ipv6Hdr),
            sizeof(ipv6_addr_t)
    );
    udpHdrRawPtr = udpHdrIov->iov.ptr;
    tmp = srcSockAddr->udpPortNo;
    *udpHdrRawPtr = (uint8_t)(tmp >> 8);
    ++udpHdrRawPtr;
    *udpHdrRawPtr = (uint8_t)tmp;
    ++udpHdrRawPtr;
    tmp = dstSockAddr->udpPortNo;
    *udpHdrRawPtr = (uint8_t)(tmp >> 8);
    ++udpHdrRawPtr;
    *udpHdrRawPtr = (uint8_t)tmp;
    ++udpHdrRawPtr;
    tmp = payloadLen;
    *udpHdrRawPtr = (uint8_t)(tmp >> 8);
    ++udpHdrRawPtr;
    *udpHdrRawPtr = (uint8_t)tmp;
    ++udpHdrRawPtr;
    tmp = 0; // checksum
    *udpHdrRawPtr = (uint8_t)(tmp >> 8);
    ++udpHdrRawPtr;
    *udpHdrRawPtr = (uint8_t)tmp;
    ++udpHdrRawPtr;
    return packet;

FAILURE_ROLLBACK_1:
    whip6_ipv6FreeExistingIPv6Packet(packet);
FAILURE_ROLLBACK_0:
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_udpUnwrapDataFromOutgoingIpv6PacketCarryingUdpDatagram(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        iov_blist_t MCS51_STORED_IN_RAM * udpHdrIov,
        iov_blist_t MCS51_STORED_IN_RAM * * payloadIovPtr,
        size_t * payloadLenPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   payloadIov;
    size_t                              payloadLen;

    if (packet == NULL || udpHdrIov == NULL)
    {
        return 1;
    }
    payloadLen = whip6_ipv6BasicHeaderGetPayloadLength(&packet->header);
    if (payloadLen < sizeof(udp_header_t) ||
            whip6_ipv6BasicHeaderGetNextHeader(&packet->header) != WHIP6_IANA_IPV6_UDP ||
            packet->firstPayloadIov != udpHdrIov ||
            udpHdrIov->iov.len != sizeof(udp_header_t))
    {
        return 1;
    }
    payloadLen -= sizeof(udp_header_t);
    payloadIov = udpHdrIov->next;
    if (whip6_iovGetTotalLength(payloadIov) < payloadLen)
    {
        return 1;
    }
    if (payloadIov != NULL)
    {
        payloadIov->prev = NULL;
        udpHdrIov->next = NULL;
    }
    whip6_ipv6FreeExistingIPv6Packet(packet);
    *payloadIovPtr = payloadIov;
    *payloadLenPtr = payloadLen;
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_udpStripeDataFromIncomingIpv6PacketCarryingUdpDatagram(
        iov_blist_iter_t MCS51_STORED_IN_RAM * iovIter,
        iov_blist_t MCS51_STORED_IN_RAM * iovSpare,
        iov_blist_t MCS51_STORED_IN_RAM * * payloadIovPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovOld;
    size_t                              offOld;

    if (whip6_iovIteratorMoveForward(iovIter, sizeof(udp_header_t)) != sizeof(udp_header_t))
    {
        return 1;
    }
    iovOld = iovIter->currElem;
    if (iovOld == NULL)
    {
        *payloadIovPtr = NULL;
        return 0;
    }
    offOld = iovIter->offset;
    iovSpare->iov.ptr = iovOld->iov.ptr + offOld;
    iovSpare->iov.len = iovOld->iov.len - offOld;
    iovSpare->next = iovOld->next;
    iovSpare->prev = NULL;
    if (iovSpare->next != NULL)
    {
        iovSpare->next->prev = iovSpare;
    }
    *payloadIovPtr = iovSpare;
    return 0;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX uint8_t whip6_udpRestoreDataToIncomingIpv6PacketCarryingUdpDatagram(
        iov_blist_iter_t MCS51_STORED_IN_RAM * iovIter,
        iov_blist_t MCS51_STORED_IN_RAM * payloadIov,
        iov_blist_t MCS51_STORED_IN_RAM * iovSpare
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    iov_blist_t MCS51_STORED_IN_RAM *   iovOld;

    iovOld = iovIter->currElem;
    if (iovOld == NULL)
    {
        return payloadIov == NULL ? 0 : 1;
    }
    if (payloadIov != iovSpare)
    {
        return 1;
    }
    if (payloadIov->next != NULL)
    {
        payloadIov->next->prev = iovOld;
    }
    iovSpare->iov.ptr = NULL;
    iovSpare->iov.len = 0;
    iovSpare->next = NULL;
    iovSpare->prev = NULL;
    return 0;
}
