/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <NetStackCompileTimeConfig.h>
#include <icmpv6/ucIcmpv6Constants.h>
#include <ipv6/ucIpv6IanaConstants.h>
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * The implementation of the IPv6 stack
 * for platforms based on Whisper Core.
 *
 * @author Konrad Iwanicki
 */
configuration CoreIPv6StackPrv
{
    provides
    {
        interface SynchronousStarter @atleastonce();
        interface IPv6PacketSourceAddressSelector as PacketSourceAddressSelector[uint8_t clientId] @atmostonce();
        interface IPv6PacketSender as PacketSender[uint8_t clientId] @atmostonce();
        interface IPv6PacketReceiver as PacketReceiver[ipv6_next_header_field_t nxtHdrId] @atmostonce();
        interface IPv6PacketReceiver as HopByHopRoutingLoopOut[ipv6_next_header_field_t nxtHdrId];
#ifndef WHIP6_IPV6_6LOWPAN_DISABLE
        interface IPv6InterfaceStateProvider as LoWPANIPv6InterfaceStateProvider;
        interface IPv6InterfaceStateUpdater as LoWPANIPv6InterfaceStateUpdater;
#endif // WHIP6_IPV6_6LOWPAN_DISABLE
#ifdef WHIP6_IPV6_ICMPV6_DISABLE
        interface StatsIncrementer<uint8_t> as DummyICMPv6NumEchoRequestsHandledStat;
#endif // WHIP6_IPV6_6LOWPAN_DISABLE
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
#ifndef WHIP6_IPV6_6LOWPAN_DISABLE
        interface LoWPANSimpleRoutingStrategy @atmostonce();
        interface LoWPANDropPacket @atmostonce();
        interface SynchronousStarter as LoWPANFixedIPv6PrefixConfigurer @atmostonce();
#endif // WHIP6_IPV6_6LOWPAN_DISABLE
        interface StatsIncrementer<uint8_t> as ICMPv6NumEchoRequestsHandledStat;
    }
}
implementation
{

    // *********************************************************************
    // *                                                                   *
    // *                       B A S I C   S T A C K                       *
    // *                                                                   *
    // *********************************************************************

    enum
    {
        NUM_NETWORK_INTERFACES = uniqueCount("IPv6Stack::Iface"),
        NUM_EXTERNAL_PROTOCOL_CLIENTS = uniqueCount("IPv6Stack::Client"),
        IPV6_STACK_CLIENT_ID_FOR_ICMPV6 = NUM_EXTERNAL_PROTOCOL_CLIENTS,
        NUM_PROTOCOL_CLIENTS = NUM_EXTERNAL_PROTOCOL_CLIENTS + 1 /* ICMPv6 */,
    };

    enum
    {
        LOWPAN_MAX_UNICAST_IFACE_ADDRS = WHIP6_LOWPAN_MAX_UNICAST_IFACE_ADDRS,
        LOWPAN_MAX_MULTICAST_IFACE_ADDRS = WHIP6_LOWPAN_MAX_MULTICAST_IFACE_ADDRS,
    };

    enum
    {
        MAX_CONCURR_IPV6_PKTS = WHIP6_IPV6_MAX_CONCURRENT_PACKETS - 2,
    };

    components BoardStartupPub as StartupPrv;
    components NetStackConfigPub as ConfigPrv;
    components IPv6InterfaceStateProviderPub as IfaceProviderPrv;
    components IPv6PacketPrototypeAllocatorPub as PacketPrototypePoolPrv;
    components PlatformIOVElementAllocatorPub as IOVChunkPoolPrv;
    components new GenericIPv6StackPub(
            NUM_NETWORK_INTERFACES,
            NUM_PROTOCOL_CLIENTS,
            MAX_CONCURR_IPV6_PKTS
    ) as GenericStackPrv;
    components new CoreIPv6StackICMPv6FilterPrv(
            IPV6_STACK_CLIENT_ID_FOR_ICMPV6
    ) as ICMPv6FilterForGenericStackPrv;

    SynchronousStarter = GenericStackPrv.SynchronousStarter;
    PacketSourceAddressSelector = ICMPv6FilterForGenericStackPrv.ExternalPacketSourceAddressSelector;
    PacketSender = ICMPv6FilterForGenericStackPrv.ExternalPacketSender;
    PacketReceiver = ICMPv6FilterForGenericStackPrv.ExternalPacketReceiver;
    HopByHopRoutingLoopOut = GenericStackPrv.HopByHopRoutingLoopOut;

    GenericStackPrv.InterfaceInit = InterfaceInit;
    GenericStackPrv.InterfaceStarter = InterfaceStarter;
    GenericStackPrv.InterfaceStateProvider = InterfaceStateProvider;
    GenericStackPrv.InterfacePacketSourceAddressSelector = InterfacePacketSourceAddressSelector;
    GenericStackPrv.InterfacePacketSender = InterfacePacketSender;
    GenericStackPrv.InterfacePacketReceiver = InterfacePacketReceiver;
    GenericStackPrv.OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol = OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol;
    GenericStackPrv.OptionalOutgoingPacketSenderQueueForProtocol = OptionalOutgoingPacketSenderQueueForProtocol;
    GenericStackPrv.HopByHopRoutingLoopIn = HopByHopRoutingLoopIn;
    GenericStackPrv.RoutingFailsOnFirstErrorOtherThanNoRoute ->
        ConfigPrv.Ipv6RoutingFailsOnFirstErrorOtherThanNoRoute;
    
    ICMPv6FilterForGenericStackPrv.SubPacketSourceAddressSelector ->    
        GenericStackPrv.PacketSourceAddressSelector;
    ICMPv6FilterForGenericStackPrv.SubPacketSender ->    
        GenericStackPrv.PacketSender;
    ICMPv6FilterForGenericStackPrv.SubPacketReceiver ->    
        GenericStackPrv.PacketReceiver;


    // *********************************************************************
    // *                                                                   *
    // *                          L O O P B A C K                          *
    // *                                                                   *
    // *********************************************************************

#ifndef WHIP6_IPV6_LOOPBACK_DISABLE

    // Loopback is active.

    enum
    {
        LOOPBACK_IFACE_IDX = unique("IPv6Stack::Iface"),
    };

    components new GenericIPv6LoopbackInterfaceMainPub(
            MAX_CONCURR_IPV6_PKTS
    ) as LoopbackIfacePrv;
    components new PlatformIPv6PacketClonerPub(
    ) as LoopbackPacketClonerPrv;

    LoopbackIfacePrv.DedicatedPacketCloner -> LoopbackPacketClonerPrv;

    IfaceProviderPrv.SubInterfaces[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;

    GenericStackPrv.InterfaceInit[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    GenericStackPrv.InterfaceStarter[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    GenericStackPrv.InterfaceStateProvider[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    GenericStackPrv.InterfacePacketSourceAddressSelector[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    GenericStackPrv.InterfacePacketSender[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    GenericStackPrv.InterfacePacketReceiver[LOOPBACK_IFACE_IDX] -> LoopbackIfacePrv;
    
#endif // WHIP6_IPV6_LOOPBACK_DISABLE


    // *********************************************************************
    // *                                                                   *
    // *                           6 L O W P A N                           *
    // *                                                                   *
    // *********************************************************************

#ifndef WHIP6_IPV6_6LOWPAN_DISABLE

    // 6LoWPAN is active.

    enum
    {
        LOWPAN_IFACE_IDX = unique("IPv6Stack::Iface"),
    };

    components CoreLoWPANStackPub as LoWPANStackPrv;

#ifdef WHIP6_IPV6_6LOWPAN_MULTIHOP_DISABLE

    components new GenericSimpleRoutingLoWPANInterfaceAdapterPub(
            LOWPAN_MAX_UNICAST_IFACE_ADDRS,
            LOWPAN_MAX_MULTICAST_IFACE_ADDRS,
            MAX_CONCURR_IPV6_PKTS
    ) as LowpanIfaceAdapterPrv;
    components new GenericObjectPoolPub(
            whip6_ipv6_in_packet_processing_state_t,
            MAX_CONCURR_IPV6_PKTS
    ) as IncomingPacketStateAllocatorPrv;

    LowpanIfaceAdapterPrv.IncomingPacketStateAllocator -> IncomingPacketStateAllocatorPrv;

    StartupPrv.InitSequence[0] -> IncomingPacketStateAllocatorPrv;
    StartupPrv.InitSequence[1] -> GenericStackPrv.Init;

#else

#error Multi-hop 6LoWPAN routing not supported!

#endif // WHIP6_IPV6_6LOWPAN_MULTIHOP_DISABLE

    LoWPANIPv6InterfaceStateProvider = LowpanIfaceAdapterPrv;
    LoWPANIPv6InterfaceStateUpdater = LowpanIfaceAdapterPrv;

    LowpanIfaceAdapterPrv.LoWPANStackStarter -> LoWPANStackPrv;
    LowpanIfaceAdapterPrv.LoWPANLinkLayerAddressProvider -> LoWPANStackPrv;
    LowpanIfaceAdapterPrv.LoWPANIPv6PacketForwarder -> LoWPANStackPrv;
    LowpanIfaceAdapterPrv.LoWPANIPv6PacketAcceptor -> LoWPANStackPrv;
    LowpanIfaceAdapterPrv.LoWPANSimpleRoutingStrategy = LoWPANSimpleRoutingStrategy;
    LowpanIfaceAdapterPrv.LoWPANDropPacket = LoWPANDropPacket;
    LowpanIfaceAdapterPrv.LoWPANAdditionalStarter = LoWPANFixedIPv6PrefixConfigurer;

    IfaceProviderPrv.SubInterfaces[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;

    GenericStackPrv.InterfaceInit[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;
    GenericStackPrv.InterfaceStarter[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;
    GenericStackPrv.InterfaceStateProvider[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;
    GenericStackPrv.InterfacePacketSourceAddressSelector[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;
    GenericStackPrv.InterfacePacketSender[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;
    GenericStackPrv.InterfacePacketReceiver[LOWPAN_IFACE_IDX] -> LowpanIfaceAdapterPrv;

#endif // WHIP6_IPV6_6LOWPAN_DISABLE


    // *********************************************************************
    // *                                                                   *
    // *                      B A S I C   I C M P V 6                      *
    // *                                                                   *
    // *********************************************************************

    components ICMPv6StackBasePrv;

    ICMPv6StackBasePrv.IPv6PacketSourceAddressSelector ->
        ICMPv6FilterForGenericStackPrv.ICMPv6PacketSourceAddressSelector;
    ICMPv6StackBasePrv.IPv6PacketSender ->
        ICMPv6FilterForGenericStackPrv.ICMPv6PacketSender;
    ICMPv6StackBasePrv.IPv6PacketReceiver ->
        ICMPv6FilterForGenericStackPrv.ICMPv6PacketReceiver;

#ifndef WHIP6_IPV6_ICMPV6_DISABLE
    components new ICMPv6DedicatedSenderPub() as ICMPv6DedicatedSenderPrv;

    components new ICMPv6EchoRequestMessageHandlerPrv() as ICMPv6EchoRequestHandlerPrv;
    components new PlatformIOVCopierPub() as ICMPv6EchoRequestIOVCopierPrv;
    
    ICMPv6EchoRequestHandlerPrv.EchoRequestReceiver -> ICMPv6StackBasePrv.ICMPv6MessageReceiver[ICMPV6_MESSAGE_TYPE_ECHO_REQUEST];
    ICMPv6EchoRequestHandlerPrv.EchoReplySender -> ICMPv6DedicatedSenderPrv.ICMPv6MessageSender[ICMPV6_MESSAGE_TYPE_ECHO_REPLY];
    ICMPv6EchoRequestHandlerPrv.NumEchoRequestsHandledStat = ICMPv6NumEchoRequestsHandledStat;
    ICMPv6EchoRequestHandlerPrv.ShouldReplyToRequestsToMulticastAddresses ->
        ConfigPrv.Icmpv6ShouldReplyToEchoRequestsToMulticastAddresses;
    ICMPv6EchoRequestHandlerPrv.DedicatedIOVCopier -> ICMPv6EchoRequestIOVCopierPrv;
#else
    DummyICMPv6NumEchoRequestsHandledStat = ICMPv6NumEchoRequestsHandledStat;
#endif // WHIP6_IPV6_ICMPV6_DISABLE
}
