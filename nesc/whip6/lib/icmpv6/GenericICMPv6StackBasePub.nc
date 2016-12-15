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
 * A generic ICMPv6 stack.
 *
 * @param num_sending_clients The number of clients
 *   that can concurrently send ICMPv6 messages.
 *   At least 1.
 * @param icmp_packet_queue_len The length
 *   of the internal packet queue. At least 1.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericICMPv6StackBasePub(
        uint8_t num_sending_clients,
        uint8_t icmp_packet_queue_len
)
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
        interface IPv6ChecksumComputer as OutgoingChecksumComputer @exactlyonce();
        interface IPv6ChecksumComputer as IncomingChecksumComputer @exactlyonce();
    }
}
implementation
{

    enum
    {
        ICMP_PACKET_QUEUE_LEN = icmp_packet_queue_len,
        NUM_SENDING_CLIENTS = num_sending_clients,
    };

    components new ICMPv6IncomingMessageDispatcherPrv(
    ) as IncomingMessageDispatcherPrv;
    components new ICMPv6OutgoingMessageForwarderVirtualizerPrv(
            NUM_SENDING_CLIENTS
    ) as OutgoingMessageForwarderPrv;
    components new WatchedQueuePub(
            whip6_ipv6_in_packet_processing_state_t *,
            uint8_t,
            ICMP_PACKET_QUEUE_LEN,
            "IncomingPacketQueuePrv"
    ) as IncomingPacketQueuePrv;
    components new WatchedQueuePub(
            uint8_t,
            uint8_t,
            NUM_SENDING_CLIENTS,
            "OutgoingClientQueuePrv"
    ) as OutgoingClientQueuePrv;
    components new BitPub() as IncomingPacketReadyBitPrv;
    components new BitPub() as OutgoingPacketReadyBitPrv;
    
    Init = IncomingMessageDispatcherPrv;
    Init = OutgoingMessageForwarderPrv;
    ICMPv6MessageSender = OutgoingMessageForwarderPrv;
    ICMPv6MessageReceiver = IncomingMessageDispatcherPrv;
    
    IncomingMessageDispatcherPrv.PacketReceiver = IPv6PacketReceiver;
    IncomingMessageDispatcherPrv.ProcessedPacketQueue -> IncomingPacketQueuePrv;
    IncomingMessageDispatcherPrv.ChecksumComputer = IncomingChecksumComputer;
    IncomingMessageDispatcherPrv.PacketReadyBit -> IncomingPacketReadyBitPrv;
    
    OutgoingMessageForwarderPrv.PacketSourceAddressSelector = IPv6PacketSourceAddressSelector;
    OutgoingMessageForwarderPrv.PacketSender = IPv6PacketSender;
    OutgoingMessageForwarderPrv.ChecksumComputer = OutgoingChecksumComputer;
    OutgoingMessageForwarderPrv.ActiveClientQueue -> OutgoingClientQueuePrv;
    OutgoingMessageForwarderPrv.PacketReadyBit -> OutgoingPacketReadyBitPrv;
}

