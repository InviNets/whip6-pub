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
#include <ipv6/ucIpv6AddressTypes.h>



/**
 * A generic module adapting the forwarder of
 * outgoing ICMPv6 messages to a single client.
 *
 * @param client_id The identifier of the client.
 *
 * @author Konrad Iwanicki
 */
generic module GenericICMPv6OutgoingMessageForwarderClientAdapterPub(
        uint8_t client_id
)
{
    provides
    {
        interface ICMPv6MessageSender[icmpv6_message_type_t msgType];
    }
    uses
    {
        interface ICMPv6MessageSender as SubICMPv6MessageSender[uint8_t clientId, icmpv6_message_type_t msgType];
    }
}
implementation
{
    enum
    {
        CLIENT_ID = client_id,
    };

    command inline error_t ICMPv6MessageSender.startSendingMessage[icmpv6_message_type_t msgType](
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddrOrNull,
            whip6_ipv6_addr_t const * dstAddr
    )
    {
        return call SubICMPv6MessageSender.startSendingMessage[CLIENT_ID, msgType](
                msgCode,
                payloadIter,
                payloadLen,
                srcAddrOrNull,
                dstAddr
        );
    }



    command inline error_t ICMPv6MessageSender.stopSendingMessage[icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter
    )
    {
        return call SubICMPv6MessageSender.stopSendingMessage[CLIENT_ID, msgType](
                payloadIter
        );
    }



    event inline void SubICMPv6MessageSender.finishSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
        if (clientId == CLIENT_ID)
        {
            signal ICMPv6MessageSender.finishSendingMessage[msgType](
                    payloadIter,
                    status
            );
        }
    }
    
    
    
    default event inline void ICMPv6MessageSender.finishSendingMessage[icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
    }
    
}

