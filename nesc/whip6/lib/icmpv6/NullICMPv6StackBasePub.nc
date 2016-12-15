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

#include <icmpv6/ucIcmpv6BasicTypes.h>



/**
 * A NULL ICMPv6 stack.
 *
 * @author Konrad Iwanicki
 */
generic module NullICMPv6StackBasePub()
{
    provides
    {
        interface Init @exactlyonce();
        interface ICMPv6MessageSender[uint8_t clientId, icmpv6_message_type_t msgType];
        interface ICMPv6MessageReceiver[icmpv6_message_type_t msgType] @atmostonce();
    }
    uses
    {
        interface IPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender @exactlyonce();
        interface IPv6PacketReceiver @exactlyonce();
    }
}
implementation
{

    command inline error_t Init.init()
    {
        return SUCCESS;
    }


    
    command inline error_t ICMPv6MessageSender.startSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            icmpv6_message_code_t msgCode,
            whip6_iov_blist_iter_t * payloadIter,
            size_t payloadLen,
            whip6_ipv6_addr_t const * srcAddrOrNull,
            whip6_ipv6_addr_t const * dstAddr
    )
    {
        return EBUSY;
    }



    command inline error_t ICMPv6MessageSender.stopSendingMessage[uint8_t clientId, icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter
    )
    {
        return EINVAL;
    }


    
    command inline void ICMPv6MessageReceiver.finishReceivingMessage[icmpv6_message_type_t msgType](
            whip6_iov_blist_iter_t * payloadIter,
            error_t status
    )
    {
    }



    event inline void IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
    }
    
    

    event inline void IPv6PacketSender.finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
    }



    event inline error_t IPv6PacketReceiver.startReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return ENOSYS;
    }
}

