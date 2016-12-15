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
 * A filter for the sending functionality
 * for IPv6 packets that is responsible for
 * closing the forwarding loop.
 *
 * @param forwarder_client_id The identifier of the
 *   forwarder client.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6PacketStackForwardingLoopFilterPrv(
    uint8_t forwarder_client_id
)
{
    provides
    {
        interface IPv6PacketSender as LocalPacketSender[uint8_t clientId] @atmostonce();
        interface IPv6PacketSender as ForwarderPacketSender @exactlyonce();
    }
    uses
    {
        interface IPv6PacketSender as SubPacketSender[uint8_t clientId] @atmostonce();
    }
}
implementation
{
    enum
    {
        FORWARDER_CLIENT_ID = forwarder_client_id,
    };



    command inline error_t LocalPacketSender.startSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        if (clientId == FORWARDER_CLIENT_ID)
        {
            return ENOSYS;
        }
        return call SubPacketSender.startSendingIPv6Packet[clientId](outPacket);
    }



    command inline error_t ForwarderPacketSender.startSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        return call SubPacketSender.startSendingIPv6Packet[FORWARDER_CLIENT_ID](outPacket);
    }



    event inline void SubPacketSender.finishSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        if (clientId == FORWARDER_CLIENT_ID)
        {
            signal ForwarderPacketSender.finishSendingIPv6Packet(
                    outPacket,
                    status
            );
        }
        else
        {
            signal LocalPacketSender.finishSendingIPv6Packet[clientId](
                    outPacket,
                    status
            );
        }
    }



    default event inline void LocalPacketSender.finishSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        // Do nothing.
    }
}

