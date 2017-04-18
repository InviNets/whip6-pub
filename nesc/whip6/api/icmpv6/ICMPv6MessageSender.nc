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
#include <icmpv6/ucIcmpv6BasicTypes.h>



/**
 * A sender of ICMPv6 messages of a given type.
 *
 * @author Konrad Iwanicki
 */
interface ICMPv6MessageSender
{

    /**
     * Starts sending a message with a given code.
     * @param msgCode The ICMPv6 code of the message.
     * @param payloadIter An I/O vector iterator pointing at
     *   the message payload (without the ICMPv6 header).
     *   Upon success the implementer of the command takes
     *   over the ownership of the iterator.
     * @param payloadLen The length of the payload
     *   in the I/O vector.
     * @param srcAddrOrNull A pointer to the IPv6 address
     *   from which the message should be sent. A NULL
     *   value is equivalent to the undefined address.
     *   The pointer must be valid throughout the whole
     *   sending process.
     * @param dstAddr A pointer to the IPv6 adddress
     *   to which the message should be sent. The pointer must
     *   be valid as long as the <tt>srcAddr</tt> pointer.
     * @return SUCCESS if sending the message has
     *   been started successfully, in which case the
     *   <tt>finishSendingMessage</tt> event is guaranteed
     *   to be signaled; an error code otherwise, in which
     *   case no <tt>finishSendingMessage</tt> event will
     *   be signaled for the message.
     */
    command error_t startSendingMessage(
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddrOrNull,
            whip6_ipv6_addr_t const * dstAddr
    );

    /**
     * Cancels sending and ICMPv6 message.
     * @param payloadIter An I/O vector iterator passed to
     *   the <tt>startSendingMessage</tt> command for
     *   the message.
     * @return SUCCESS if sending the message has been
     *   canceled successfully, in which case no
     *   <tt>finishSendingMessage</tt> event will be signaled
     *   for the message; EINVAL if the message is not being
     *   sent; EBUSY if canceling the message cannot be
     *   terminated, in which case the <tt>finishSendingMessage</tt>
     *   event will be signaled.
     */
    command error_t stopSendingMessage(
            whip6_iov_blist_iter_t * payloadIter
    );

    /**
     * Signals that sending an ICMPv6 message has completed.
     * To check whether the message has actually been
     * transmitted, one should inspect the <tt>status</tt>.
     * @param payloadIter An I/O vector iterator passed to
     *   the <tt>startSendingMessage</tt> command for
     *   the message. The iterator points at the same place
     *   as when starting to send the message.
     * @param status The sending status.
     */
    event void finishSendingMessage(
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    );
}
