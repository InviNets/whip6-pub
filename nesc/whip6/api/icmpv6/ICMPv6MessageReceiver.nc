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
#include <icmpv6/ucIcmpv6BasicTypes.h>



/**
 * A receiver of ICMPv6 messages of a given type.
 *
 * @author Konrad Iwanicki
 */
interface ICMPv6MessageReceiver
{

    /**
     * Signaled when a message with given code
     * is received to check whether reception
     * of messages with the code is supported.
     * @param msgCode The code.
     * @return TRUE if the reception of a message
     *   with the code is supported or FALSE otherwise.
     */
    event bool isCodeSupported(icmpv6_message_code_t msgCode);

    /**
     * Starts receiving a message with a given code.
     * @param msgCode The ICMPv6 code of the message.
     * @param payloadIter An I/O vector iterator pointing at
     *   the message payload (without the ICMPv6 header).
     *   Upon success the implementer of the handler takes
     *   over the ownership of the iterator. The iterator
     *   can be freely modified.
     * @param payloadLen The length of the payload
     *   in the I/O vector.
     * @param srcAddr A pointer to the IPv6 address
     *   from which the message arrived. The pointer is
     *   valid as long as the message is being received,
     *   that is, until the event returns with a failure
     *   code or until the <tt>finishReceivingMessage</tt>
     *   event is invoked.
     * @param dstAddr A pointer to the IPv6 adddress
     *   at which the message arrived. The pointer is
     *   valid as long as the <tt>srcAddr</tt> pointer.
     * @return SUCCESS if receiving the message has
     *   been started successfully, in which case the
     *   <tt>finishReceivingMessage</tt> command must be
     *   invoked for the message; an error code otherwise, in which
     *   case no <tt>finishReceivingMessage</tt> command must
     *   be invoked for the message.
     */
    event error_t startReceivingMessage(
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddr,
            whip6_ipv6_addr_t const * dstAddr
    );

    /**
     * Finishes receiving an ICMPv6 message.
     * @param payloadIter An I/O vector iterator obtained
     *   in the <tt>startReceivingMessage</tt> event for
     *   the message.
     * @param status The reception status.
     */
    command void finishReceivingMessage(
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    );
}

