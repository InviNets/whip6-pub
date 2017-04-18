/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6GenericInterfaceStateTypes.h>



/**
 * A generic part of the IPv6 stack.
 *
 * The configuration should be instantiated
 * and wired to appropriate components to form
 * a stack customized for a given platform.
 *
 * @param num_ifaces The number of network interfaces,
 *   which provide the low-level IPv6 interfaces.
 * @param num_protocols The number of unique higher-layer
 *   protocols that make use of the stack.
 * @param packet_queue_length The length of the internal
 *   packet queue for the IPv6 stack.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIPv6StackPub(
        ipv6_net_iface_id_t num_ifaces,
        uint8_t num_protocols,
        uint8_t packet_queue_length
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter @atleastonce();
        interface IPv6PacketSourceAddressSelector as PacketSourceAddressSelector[uint8_t clientId] @atmostonce();
        interface IPv6PacketSender as PacketSender[uint8_t clientId] @atmostonce();
        interface IPv6PacketReceiver as PacketReceiver[ipv6_next_header_field_t nxtHdrId] @atmostonce();
        interface IPv6PacketReceiver as HopByHopRoutingLoopOut[ipv6_next_header_field_t nxtHdrId];
    }
    uses
    {
        interface Init as InterfaceInit[ipv6_net_iface_id_t ifaceId];
        interface SynchronousStarter as InterfaceStarter[ipv6_net_iface_id_t ifaceId];
        interface IPv6InterfaceStateProvider as InterfaceStateProvider[ipv6_net_iface_id_t ifaceId];
        interface IPv6PacketSourceAddressSelector as InterfacePacketSourceAddressSelector[ipv6_net_iface_id_t ifaceId];
        interface IPv6PacketSender as InterfacePacketSender[ipv6_net_iface_id_t ifaceId];
        interface IPv6PacketReceiver as InterfacePacketReceiver[ipv6_net_iface_id_t ifaceId];
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol[uint8_t clientId];
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as OptionalOutgoingPacketSenderQueueForProtocol[uint8_t clientId];
        // NOTICE iwanicki 2014-03-15:
        // This interface is here, so that the layers
        // that we support (e.g., UDP) can tell that
        // UDP headers are recognized headers, and thus,
        // packets containing them may be forwarded.
        // Packets containing unrecognized headers are
        // not forwarded (see PlatformRawUDPSocketManagerPrv).
        interface IPv6PacketReceiver as HopByHopRoutingLoopIn[ipv6_next_header_field_t nxtHdrId];
        interface ConfigValue<bool> as RoutingFailsOnFirstErrorOtherThanNoRoute;
    }
}
implementation
{
    enum
    {
        NUM_IFACES = num_ifaces,
        FORWARDER_PROTOCOL_ID = num_protocols,
        NUM_PROTOCOLS = num_protocols + 1,
    };

    enum
    {
        PACKET_QUEUE_LENGTH = packet_queue_length,
    };

    components new GenericIPv6StackGluePrv(
            NUM_IFACES
    ) as GluePrv;
    components new IPv6OutgoingPacketStackVirtualizerPrv(
            NUM_PROTOCOLS
    ) as OutVirtualizerPrv;
    components new IPv6DefaultPacketRoutingPolicyMainPrv(
    ) as RoutingPolicyPrv;
    components new IPv6IncomingPacketProcessorMainPrv(
    ) as ProcessorPrv;
    // NOTICE iwanicki 2014-03-15:
    // Look below for an explanation.
    // components IPv6ExtensionHeaderFailerForIncomingPacketProcessorPrv as ExtHdrProcessorFailerPrv;
    components new IPv6IncomingPacketProcessorDispatchDecoratorPrv(
    ) as ClassifierPrv;
    components new IPv6IncomingPacketForwarderPrv(
            PACKET_QUEUE_LENGTH
    ) as InForwarderPrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            PACKET_QUEUE_LENGTH,
            "RoutingPolicyPacketQueuePrv"
    ) as RoutingPolicyPacketQueuePrv;
    components new WatchedQueuePub(
            whip6_ipv6_in_packet_processing_state_t *,
            uint8_t,
            PACKET_QUEUE_LENGTH,
            "ProcessorPacketQueuePrv"
    ) as ProcessorPacketQueuePrv;
    components new IPv6PacketStackForwardingLoopFilterPrv(
            FORWARDER_PROTOCOL_ID
    ) as ForwardingLoopFilterPrv;

    Init = GluePrv.Init;
    SynchronousStarter = GluePrv.AllStarter;
    PacketSourceAddressSelector = OutVirtualizerPrv.IPv6PacketSourceAddressSelector;
    PacketSender = ForwardingLoopFilterPrv.LocalPacketSender;
    PacketReceiver = ClassifierPrv.EndToEndReceiver;
    HopByHopRoutingLoopOut = ClassifierPrv.HopByHopReceiver;

    GluePrv.IfaceInit = InterfaceInit;
    GluePrv.IfaceStarter = InterfaceStarter;
    GluePrv.IfaceStateProvider = InterfaceStateProvider;

    OutVirtualizerPrv.SubIPv6PacketSourceAddressSelector -> RoutingPolicyPrv.PacketSourceAddressSelector;
    OutVirtualizerPrv.SubIPv6PacketSender -> RoutingPolicyPrv.PacketSender;
    OutVirtualizerPrv.AddressSelectionQueue = OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol;
    OutVirtualizerPrv.SendingQueue = OptionalOutgoingPacketSenderQueueForProtocol;

    RoutingPolicyPrv.SubPacketSender = InterfacePacketSender;
    RoutingPolicyPrv.SubPacketSourceAddressSelector = InterfacePacketSourceAddressSelector;
    RoutingPolicyPrv.SubInterfaceStateProvider = InterfaceStateProvider;
    RoutingPolicyPrv.RoutedPacketQueue -> RoutingPolicyPacketQueuePrv;
    RoutingPolicyPrv.FailOnFirstErrorOtherThanNoRoute = RoutingFailsOnFirstErrorOtherThanNoRoute;

    ProcessorPrv.SubIPv6PacketReceiver = InterfacePacketReceiver;
    ProcessorPrv.SubInterfaceStateProvider = InterfaceStateProvider;
    ProcessorPrv.ProcessedPacketQueue -> ProcessorPacketQueuePrv;

    ClassifierPrv.SubIPv6PacketReceiver -> ProcessorPrv.IPv6PacketReceiver;

    InForwarderPrv.IPv6PacketReceiver = HopByHopRoutingLoopIn;
    InForwarderPrv.IPv6PacketSender -> ForwardingLoopFilterPrv.ForwarderPacketSender;
    
    // NOTICE iwanicki 2014-03-15:
    // This is not necessary because packets
    // with unrecognized headers are dropped
    // by default (see the default method in
    // the classifier).
    // ExtHdrProcessorFailerPrv.IPv6PacketReceiver[WHIP6_IANA_IPV6_NO_NEXT_HEADER] ->
    //     ClassifierPrv.EndToEndReceiver[WHIP6_IANA_IPV6_NO_NEXT_HEADER];
    
    ForwardingLoopFilterPrv.SubPacketSender -> OutVirtualizerPrv.IPv6PacketSender;
}
