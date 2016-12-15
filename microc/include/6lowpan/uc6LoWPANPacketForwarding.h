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

#ifndef __WHIP6_MICROC_6LOWPAN_6LOWPAN_PACKET_FORWARDING_H__
#define __WHIP6_MICROC_6LOWPAN_6LOWPAN_PACKET_FORWARDING_H__

/**
 * @file
 * @author Konrad Iwanicki
 *
 * This file contains IPv6 packet forwarding functionality
 * for 6LoWPAN compatible network interfaces. This is only
 * support functionality for NesC code.
 */

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



struct lowpan_ipv6_packet_ready_for_forwarding_s;
/**
 * An IPv6 packet staged for forwarding
 * via a 6LoWPAN compatible interface.
 */
typedef struct lowpan_ipv6_packet_ready_for_forwarding_s   lowpan_ipv6_packet_ready_for_forwarding_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_ipv6_packet_ready_for_forwarding_t)


struct lowpan_ipv6_packet_ready_for_forwarding_s
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   next;
    ipv6_packet_t MCS51_STORED_IN_RAM *                               packet;
    uint8_t                                                           status;
    ieee154_addr_t                                                    addr;
};


/**
 * The size of a queue of IPv6 packets staged
 * for forwarding via a 6LoWPAN compatible interface.
 */
typedef uint8_t lowpan_ipv6_packet_ready_for_forwarding_queue_size_t;

/**
 * A queue of IPv6 packets staged for forwarding
 * via a 6LoWPAN compatible interface.
 */
typedef struct lowpan_ipv6_packet_ready_for_forwarding_queue_s
{
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   stagedQueueFirst;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   stagedQueueLast;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   completedQueueFirst;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   completedQueueLast;
    lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM *   poolFirst;
    lowpan_ipv6_packet_ready_for_forwarding_queue_size_t              numInPool;
    lowpan_ipv6_packet_ready_for_forwarding_queue_size_t              numInQueue;
} lowpan_ipv6_packet_ready_for_forwarding_queue_t;

MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE(lowpan_ipv6_packet_ready_for_forwarding_queue_t)



/**
 * Returns a packet associated with an element of
 * a queue of IPv6 packets staged for forwarding.
 * @param queueElem The element of the queue.
 * @return A pointer to the packet associated with
 *   the element.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ipv6_packet_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetPacketForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns an 802.15.4 address associated with an element
 * of a queue of IPv6 packets staged for forwarding.
 * @param queueElem The element of the queue.
 * @return A pointer to the 802.15.4 address associated
 *   with the element.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX ieee154_addr_t MCS51_STORED_IN_RAM const * whip6_lowpanPacketForwardingStagingQueueGetLinkLayerAddrForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns a status associated with an element
 * of a queue of IPv6 packets staged for forwarding.
 * @param queueElem The element of the queue.
 * @return A status associated with the element.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX uint8_t whip6_lowpanPacketForwardingStagingQueueGetStatusForQueueElement(
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queueElem
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Initializes a queue of IPv6 packets staged for
 * forwarding via a 6LoWPAN-compatible interface.
 * @param queue The queue to be initialized.
 * @param queuePoolPtr A pointer to an array that
 *   will serve as a pool of the queue elements.
 *   Must NOT be NULL.
 * @param queuePoolLen The length of the pool.
 *   Must NOT be zero.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanPacketForwardingStagingQueueInit(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * queuePoolPtr,
        lowpan_ipv6_packet_ready_for_forwarding_queue_size_t queuePoolLen
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Enqueues an IPv6 packet to a queue of IPv6 packets
 * staged for forwarding via a 6LoWPAN-compatible
 * interface.
 * @param queue The queue to which the packet should
 *   be enqueued.
 * @param packet A pointer to the packet to be enqueued.
 * @param llAddr A pointer to an IEEE 802.15.4 address
 *   to which the packet should be forwarded.
 * @return A pointer to a queue element allocated for the
 *   packet or NULL if there has been no memory to allocate
 *   the element (hence, the packet has not been enqueued).
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueEnqueuePacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM * packet,
        ieee154_addr_t MCS51_STORED_IN_RAM const * llAddr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Searches for an IPv6 packet in a queue of IPv6 packets
 * staged for forwarding via a 6LoWPAN-compatible
 * interface.
 * @param queue The queue in which the packet should
 *   be sought.
 * @param packet A pointer to the packet to be searched.
 * @param prevElementPtr A pointer that will receive
 *   a pointer to the previous element in the queue,
 *   which may be used, for instance, for removing
 *   the packet from the queue. Can be NULL.
 * @return A pointer to the element corresponding to
 *   the packet or NULL if such an element has not
 *   been found in the queue.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueFindStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * * prevElementPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Moves an IPv6 packet from a queue of IPv6 packets
 * staged for forwarding via a 6LoWPAN-compatible
 * interface to the end of the queue of completed
 * packets for the interface.
 * @param queue The queue.
 * @param prevQueueElem The previous element in the
 *   queue of staged packets.
 * @param currQueueElem The element in the queue of
 *   staged packets to be removed.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanPacketForwardingStagingQueueMarkPacketAsCompleted(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * prevQueueElem,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * currQueueElem
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Searches for an IPv6 packet in a queue of IPv6 packets
 * forwarding which via a 6LoWPAN-compatible interface
 * has completed.
 * @param queue The queue in which the packet should
 *   be sought.
 * @param packet A pointer to the packet to be searched.
 * @param prevElementPtr A pointer that will receive
 *   a pointer to the previous element in the queue,
 *   which may be used, for instance, for removing
 *   the packet from the queue. Can be NULL.
 * @return A pointer to the element corresponding to
 *   the packet or NULL if such an element has not
 *   been found in the queue.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueFindCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        ipv6_packet_t MCS51_STORED_IN_RAM const * packet,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * * prevElementPtr
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;

/**
 * Returns the first element in the queue of IPv6 packets
 * staged for forwarding via a 6LoWPAN-compatible interface.
 * @param queue The queue.
 * @return A pointer to a queue element corresponding
 *   to the packet or NULL if the queue is empty.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetFirstStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the next element in the queue of IPv6 packets
 * staged for forwarding via a 6LoWPAN-compatible interface.
 * @param queue The queue.
 * @param elem A pointer to the current queue element.
 * @return A pointer to the next element in the queue
 *   or NULL if such an element does not exist.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetNextStagedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue,
        lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * elem
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Returns the first element in the queue of IPv6 packets
 * forwarding which via a 6LoWPAN-compatible interface
 * has completed.
 * @param queue The queue.
 * @return A pointer to a queue element corresponding
 *   to the packet or NULL if the queue is empty.
 */
WHIP6_MICROC_INLINE_DECL_PREFIX lowpan_ipv6_packet_ready_for_forwarding_t MCS51_STORED_IN_RAM * whip6_lowpanPacketForwardingStagingQueueGetFirstCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_INLINE_DECL_SUFFIX;

/**
 * Removes the first element in the queue of IPv6 packets
 * forwarding which via a 6LoWPAN-compatible interface
 * has completed.
 * @param queue The queue.
 */
WHIP6_MICROC_EXTERN_DECL_PREFIX void whip6_lowpanPacketForwardingStagingQueueRemoveFirstCompletedPacket(
        lowpan_ipv6_packet_ready_for_forwarding_queue_t MCS51_STORED_IN_RAM * queue
) WHIP6_MICROC_EXTERN_DECL_SUFFIX;


#include <6lowpan/detail/uc6LoWPANPacketForwardingImpl.h>

#endif /* __WHIP6_MICROC_6LOWPAN_6LOWPAN_PACKET_FORWARDING_H__ */
