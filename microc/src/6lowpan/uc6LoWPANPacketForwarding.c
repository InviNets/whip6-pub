/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <6lowpan/uc6LoWPANPacketForwarding.h>
#include <ieee154/ucIeee154AddressManipulation.h>



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanPacketForwardingStagingQueueInit(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queuePoolPtr,
        lowpan_ipv6_packet_ready_for_forwarding_queue_size_t queuePoolLen
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * poolFirst;

    queue->stagedQueueFirst = NULL;
    queue->stagedQueueLast = NULL;
    queue->completedQueueFirst = NULL;
    queue->completedQueueLast = NULL;
    queue->numInPool = queuePoolLen;
    queue->numInQueue = 0;
    for (poolFirst = NULL; queuePoolLen > 0; --queuePoolLen)
    {
        queuePoolPtr->next = poolFirst;
        poolFirst = queuePoolPtr;
        ++queuePoolPtr;
    }
    queue->poolFirst = poolFirst;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueEnqueuePacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        ieee154_addr_t MCS51_STORED_IN_RAM const * llAddr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem;

    queueElem = queue->poolFirst;
    if (queueElem == NULL)
    {
        return NULL;
    }
    queue->poolFirst = queueElem->next;
    if (queue->stagedQueueFirst == NULL)
    {
        queue->stagedQueueFirst = queueElem;
    }
    else
    {
        queue->stagedQueueLast->next = queueElem;
    }
    queue->stagedQueueLast = queueElem;
    --queue->numInPool;
    ++queue->numInQueue;
    queueElem->next = NULL;
    queueElem->packet = packet;
    queueElem->status = 0;
    whip6_ieee154AddrAnyCpy(llAddr, &queueElem->addr);
    return queueElem;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueFindStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * * prevElementPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * currQueueElem;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * prevQueueElem;

    prevQueueElem = NULL;
    currQueueElem = queue->stagedQueueFirst;
    while (currQueueElem != NULL)
    {
        if (currQueueElem->packet == packet)
        {
            if (prevElementPtr != NULL)
            {
                *prevElementPtr = prevQueueElem;
            }
            return currQueueElem;
        }
        prevQueueElem = currQueueElem;
        currQueueElem = currQueueElem->next;
    }
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanPacketForwardingStagingQueueMarkPacketAsCompleted(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * prevQueueElem,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * currQueueElem
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    // Remove from the staging queue.
    if (prevQueueElem == NULL)
    {
        queue->stagedQueueFirst = currQueueElem->next;
    }
    else
    {
        prevQueueElem->next = currQueueElem->next;
    }
    currQueueElem->next = NULL;
    if (currQueueElem == queue->stagedQueueLast)
    {
        queue->stagedQueueLast = prevQueueElem;
    }
    // Insert into the completed queue.
    if (queue->completedQueueFirst == NULL)
    {
        queue->completedQueueFirst = currQueueElem;
    }
    else
    {
        queue->completedQueueLast->next = currQueueElem;
    }
    queue->completedQueueLast = currQueueElem;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueFindCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * * prevElementPtr
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * currQueueElem;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * prevQueueElem;

    prevQueueElem = NULL;
    currQueueElem = queue->completedQueueFirst;
    while (currQueueElem != NULL)
    {
        if (currQueueElem->packet == packet)
        {
            if (prevElementPtr != NULL)
            {
                *prevElementPtr = prevQueueElem;
            }
            return currQueueElem;
        }
        prevQueueElem = currQueueElem;
        currQueueElem = currQueueElem->next;
    }
    return NULL;
}



WHIP6_MICROC_EXTERN_DEF_PREFIX void whip6_lowpanPacketForwardingStagingQueueRemoveFirstCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_EXTERN_DEF_SUFFIX
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * firstQueueElem;
    firstQueueElem = queue->completedQueueFirst;
    queue->completedQueueFirst = firstQueueElem->next;
    if (queue->completedQueueLast == firstQueueElem)
    {
        queue->completedQueueLast = NULL;
    }
    firstQueueElem->next = queue->poolFirst;
    queue->poolFirst = firstQueueElem;
    ++queue->numInPool;
    --queue->numInQueue;
}
