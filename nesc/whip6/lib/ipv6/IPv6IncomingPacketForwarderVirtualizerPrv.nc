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
 * A forwarder for incoming packets.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6IncomingPacketForwarderVirtualizerPrv()
{
    provides
    {
        interface IPv6PacketReceiver @exactlyonce();
    }
    uses
    {
        interface IPv6PacketReceiver as SubIPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId];
    }
}
implementation
{

//#define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)

    event inline error_t SubIPv6PacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return signal IPv6PacketReceiver.startReceivingIPv6Packet(inPacket);
    }



    command inline void IPv6PacketReceiver.finishReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        call SubIPv6PacketReceiver.finishReceivingIPv6Packet[inPacket->nextHeaderId](inPacket, status);
    }



    default command inline void SubIPv6PacketReceiver.finishReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        local_assert(FALSE);
    }


#undef local_assert
}

