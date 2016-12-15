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

#include <ipv6/ucIpv6HeaderProcessorTypes.h>



/**
 * A decorator processing incoming IPv6 packets that
 * dispatches the packets to specific processors based
 * on whether the present node is a destination of the
 * packet or not.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6IncomingPacketProcessorDispatchDecoratorPrv()
{
    provides
    {
        interface IPv6PacketReceiver as HopByHopReceiver[ipv6_next_header_field_t nxtHdrId];
        interface IPv6PacketReceiver as EndToEndReceiver[ipv6_next_header_field_t nxtHdrId];
    }
    uses
    {
        interface IPv6PacketReceiver as SubIPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId] @exactlyonce();
    }
}
implementation
{

    event inline error_t SubIPv6PacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        if ((inPacket->flags & WHIP6_IPV6_IN_PACKET_PROCESSING_STATE_FLAG_DESTINED_AT_IFACE) != 0)
        {
            return signal EndToEndReceiver.startReceivingIPv6Packet[nxtHdrId](inPacket);
        }
        else
        {
            return signal HopByHopReceiver.startReceivingIPv6Packet[nxtHdrId](inPacket);
        }
    }



    command inline void HopByHopReceiver.finishReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        call SubIPv6PacketReceiver.finishReceivingIPv6Packet[nxtHdrId](inPacket, status);
    }



    command inline void EndToEndReceiver.finishReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        call SubIPv6PacketReceiver.finishReceivingIPv6Packet[nxtHdrId](inPacket, status);
    }



    default event inline error_t HopByHopReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return ENOSYS;
    }



    default event inline error_t EndToEndReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return ENOSYS;
    }



    default command inline void SubIPv6PacketReceiver.finishReceivingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
    }

#undef local_dbg

}

