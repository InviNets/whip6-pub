/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_PACKET_FORWARDING_IMPL_H__
#define __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_PACKET_FORWARDING_IMPL_H__

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_PACKET_FORWARDING_H__
#error Do not include this file directly!
#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_PACKET_FORWARDING_H__ */



WHIP6_MICROC_INLINE_DEF_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return queueElem->packet;
}



WHIP6_MICROC_INLINE_DEF_PREFIX ieee154_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return &queueElem->addr;
}



WHIP6_MICROC_INLINE_DEF_PREFIX uint8_t whip6_lowpanPacketForwardingStagingQueueGetStatusForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return queueElem->status;
}



WHIP6_MICROC_INLINE_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetFirstStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return queue->stagedQueueFirst;
}



WHIP6_MICROC_INLINE_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetNextStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * elem
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    (void)queue;
    return elem->next;
}



WHIP6_MICROC_INLINE_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetFirstCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_INLINE_DEF_SUFFIX
{
    return queue->completedQueueFirst;
}



#endif /* __WHIP6_MICROC_6LOWPAN_DETAIL_6LOWPAN_PACKET_FORWARDING_IMPL_H__ */
