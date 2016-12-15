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
 * A network-layer forwarder for incoming packets.
 *
 * @param queue_len The length of the forwarding queue.
 *
 * @author Konrad Iwanicki
 */
generic configuration IPv6IncomingPacketForwarderPrv(
        uint8_t queue_len
)
{
    uses
    {
        interface IPv6PacketReceiver as IPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId];
        interface IPv6PacketSender;
    }
}
implementation
{
    enum
    {
        FORWARDING_QUEUE_LEN = queue_len,
    };

    components new IPv6IncomingPacketForwarderMainPrv() as MainPrv;
    components new IPv6IncomingPacketForwarderVirtualizerPrv() as VirtualizerPrv;
    components new BitPub() as ForwardingInProgressBitPrv;
    components new WatchedQueuePub(
            whip6_ipv6_in_packet_processing_state_t *,
            uint8_t,
            FORWARDING_QUEUE_LEN,
            "ForwardedPacketQueuePrv"
    ) as ForwardedPacketQueuePrv;

    IPv6PacketReceiver = VirtualizerPrv.SubIPv6PacketReceiver;

    MainPrv.PacketReceiver -> VirtualizerPrv.IPv6PacketReceiver;
    MainPrv.PacketSender = IPv6PacketSender;
    MainPrv.ForwardedPacketQueue -> ForwardedPacketQueuePrv;
    MainPrv.ForwardingInProgressBit -> ForwardingInProgressBitPrv;
}

