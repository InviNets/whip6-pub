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




/**
 * A module that hacks ICMPv6 into the basic IPv6
 * stack on WhisperCore-based platforms.
 *
 * @param icmpv6_client_id The identifier of the ICMPv6 client.
 *
 * @author Konrad Iwanicki
 */
generic module CoreIPv6StackICMPv6FilterPrv(
    uint8_t icmpv6_client_id
)
{
    provides
    {
        interface IPv6PacketSourceAddressSelector as ExternalPacketSourceAddressSelector[uint8_t clientId] @atmostonce();
        interface IPv6PacketSourceAddressSelector as ICMPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender as ExternalPacketSender[uint8_t clientId] @atmostonce();
        interface IPv6PacketSender as ICMPv6PacketSender @exactlyonce();
        interface IPv6PacketReceiver as ExternalPacketReceiver[ipv6_next_header_field_t nxtHdrId] @atmostonce();
        interface IPv6PacketReceiver as ICMPv6PacketReceiver @exactlyonce();
    }
    uses
    {
        interface IPv6PacketSourceAddressSelector as SubPacketSourceAddressSelector[uint8_t clientId] @exactlyonce();
        interface IPv6PacketSender as SubPacketSender[uint8_t clientId] @exactlyonce();
        interface IPv6PacketReceiver as SubPacketReceiver[ipv6_next_header_field_t nxtHdrId] @exactlyonce();
    }
}
implementation
{

    enum
    {
        ICMPV6_CLIENT_ID = icmpv6_client_id,
    };



    command inline error_t ExternalPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        if (clientId == ICMPV6_CLIENT_ID)
        {
            return ENOSYS;
        }
        return call SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[clientId](outPacket);
    }



    command inline error_t ICMPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        return call SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[ICMPV6_CLIENT_ID](outPacket);
    }
    
    

    event inline void SubPacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        if (clientId == ICMPV6_CLIENT_ID)
        {
            signal ICMPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
                    outPacket,
                    status
            );
        }
        else
        {
            signal ExternalPacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[clientId](
                    outPacket,
                    status
            );
        }
    }



    default event inline void ExternalPacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        // Do nothing.
    }
    
    
    
    command inline error_t ExternalPacketSender.startSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        if (clientId == ICMPV6_CLIENT_ID)
        {
            return ENOSYS;
        }
        return call SubPacketSender.startSendingIPv6Packet[clientId](outPacket);
    }
    
    
    
    command inline error_t ICMPv6PacketSender.startSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        return call SubPacketSender.startSendingIPv6Packet[ICMPV6_CLIENT_ID](outPacket);
    }
    
    
    
    event inline void SubPacketSender.finishSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        if (clientId == ICMPV6_CLIENT_ID)
        {
            signal ICMPv6PacketSender.finishSendingIPv6Packet(
                    outPacket,
                    status
            );
        }
        else
        {
            signal ExternalPacketSender.finishSendingIPv6Packet[clientId](
                    outPacket,
                    status
            );
        }
    }



    default event inline void ExternalPacketSender.finishSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        // Do nothing.
    }



    event inline error_t SubPacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        if (nxtHdrId == WHIP6_IANA_IPV6_ICMP)
        {
            return signal ICMPv6PacketReceiver.startReceivingIPv6Packet(inPacket);
        }
        else
        {
            return signal ExternalPacketReceiver.startReceivingIPv6Packet[nxtHdrId](inPacket);
        }
    }
    
    
    
    default event inline error_t ExternalPacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return ENOSYS;
    }
    
    
    
    command inline void ExternalPacketReceiver.finishReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        if (nxtHdrId != WHIP6_IANA_IPV6_ICMP)
        {
            call SubPacketReceiver.finishReceivingIPv6Packet[nxtHdrId](
                    inPacket,
                    status
            );
        }
    }
    
    
    
    command inline void ICMPv6PacketReceiver.finishReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        call SubPacketReceiver.finishReceivingIPv6Packet[WHIP6_IANA_IPV6_ICMP](
                inPacket,
                status
        );
    }
}

