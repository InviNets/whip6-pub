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

#ifndef __WHIP6_MICROC_IPV6_DETAIL_IPV6_PACKET_ALLOCATION_IMPL_H__
#define __WHIP6_MICROC_IPV6_DETAIL_IPV6_PACKET_ALLOCATION_IMPL_H__

#ifndef __WHIP6_MICROC_IPV6_IPV6_PACKET_ALLOCATION_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_IPV6_IPV6_PACKET_ALLOCATION_H__ */

#include <base/ucIoVecAllocation.h>
#include <external/ucExternalIpv6Allocators.h>



WHIP6_MICROC_PRIVATE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_ipv6AllocatePacket(
        ipv6_payload_length_t payloadLength
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    ipv6_packet_t MCS51_STORED_IN_RAM *   packet;

    packet = whip6_ipv6AllocNewIPv6Packet();
    if (packet == NULL)
    {
        goto FAILURE_ROLLBACK_0;
    }
    if (payloadLength == 0)
    {
        packet->firstPayloadIov = NULL;
        packet->lastPayloadIov = NULL;
    }
    else
    {
        packet->firstPayloadIov =
                whip6_iovAllocateChain(
                        payloadLength,
                        &packet->lastPayloadIov
                );
        if (packet->firstPayloadIov == NULL)
        {
            goto FAILURE_ROLLBACK_1;
        }
    }
    return packet;

FAILURE_ROLLBACK_1:
    whip6_ipv6FreeExistingIPv6Packet(packet);
FAILURE_ROLLBACK_0:
    return NULL;
}



WHIP6_MICROC_PRIVATE_DEF_PREFIX void whip6_ipv6FreePacket(
        ipv6_packet_t MCS51_STORED_IN_RAM * packet
) WHIP6_MICROC_PRIVATE_DEF_SUFFIX
{
    whip6_iovFreeChain(packet->firstPayloadIov);
    whip6_ipv6FreeExistingIPv6Packet(packet);
}



#endif /* __WHIP6_MICROC_IPV6_DETAIL_IPV6_PACKET_ALLOCATION_IMPL_H__ */
