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

#include "BaseCompileTimeConfig.h"
#include "NetStackCompileTimeConfig.h"



/**
 * The generic manager for raw UDP sockets.
 *
 * @author Konrad Iwanicki
 */
configuration GenericRawUDPSocketManagerPrv
{
    provides
    {
        interface UDPSocketController[udp_socket_id_t sockId];        
        interface UDPRawReceiver[udp_socket_id_t sockId];
        interface UDPRawSender[udp_socket_id_t sockId];
    }
}
implementation
{
    enum
    {
        NUM_SOCKETS = uniqueCount("GenericRawUDPSocketManagerPrv::Socket"),
    };

    enum
    {
        MAX_BYTES_PROCESSED_PER_TASK = WHIP6_BASE_MAX_BYTES_PROCESSED_PER_TASK,
    };

    enum
    {
        IPV6_STACK_CLIENT_ID = unique("IPv6Stack::Client"),
    };

    components BoardStartupPub as GlobalMainPrv;
    components IPv6InterfaceStateProviderPub as IfaceStateProviderPrv;
    components InternalIPv6StackPub as IPv6StackPrv;
    components PlatformRandomPub as RandomPrv;
    components new UDPRawSocketManagerMainPrv(
            NUM_SOCKETS,
            MAX_BYTES_PROCESSED_PER_TASK
    ) as ImplPrv;
    components new QueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            NUM_SOCKETS
    ) as PacketSourceAddressSelectorQueueForStackPrv;
    components new QueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            NUM_SOCKETS
    ) as PacketSenderQueueForStackPrv;

    UDPSocketController = ImplPrv.UDPSocketController;
    UDPRawReceiver = ImplPrv.UDPRawReceiver;
    UDPRawSender = ImplPrv.UDPRawSender;

    GlobalMainPrv.InitSequence[1] -> ImplPrv;

    ImplPrv.IPv6PacketReceiver -> IPv6StackPrv.PacketReceiver[WHIP6_IANA_IPV6_UDP];
    ImplPrv.IPv6PacketSender -> IPv6StackPrv.PacketSender[IPV6_STACK_CLIENT_ID];
    ImplPrv.IPv6PacketSourceAddressSelector -> IPv6StackPrv.PacketSourceAddressSelector[IPV6_STACK_CLIENT_ID];
    ImplPrv.IPv6InterfaceStateProvider -> IfaceStateProviderPrv.Interfaces;
    ImplPrv.Random -> RandomPrv;
    
    IPv6StackPrv.HopByHopRoutingLoopIn[WHIP6_IANA_IPV6_UDP] ->
        IPv6StackPrv.HopByHopRoutingLoopOut[WHIP6_IANA_IPV6_UDP];
    IPv6StackPrv.OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol[IPV6_STACK_CLIENT_ID] ->
        PacketSourceAddressSelectorQueueForStackPrv;
    IPv6StackPrv.OptionalOutgoingPacketSenderQueueForProtocol[IPV6_STACK_CLIENT_ID] ->
        PacketSenderQueueForStackPrv;
}

