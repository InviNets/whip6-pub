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
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * A generic adapter that transforms a 6LoWPAN-compatible
 * stack into an IPv6 network interface with simple
 * routing based on a single fixed default route.
 *
 * @param max_num_unicast_addrs The maximal number of unicast IPv6
 *   addresses the interface is expected to be configured
 *   with.
 * @param max_num_multicast_addrs The maximal number of multicast
 *   IPv6 addresses the interface is expected to be configured
 *   with.
 * @param max_num_concurr_packets The maximal number of concurrently
 *   processed IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericSimpleRoutingLoWPANInterfaceAdapterPub(
        ipv6_net_iface_addr_count_t max_num_unicast_addrs,
        ipv6_net_iface_addr_count_t max_num_multicast_addrs,
        uint8_t max_num_concurr_packets
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter @atleastonce();
        interface IPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender @exactlyonce();
        interface IPv6PacketReceiver @exactlyonce();
        interface IPv6InterfaceStateProvider @atleastonce();
        interface IPv6InterfaceStateUpdater;
    }
    uses
    {
        interface SynchronousStarter as LoWPANStackStarter @exactlyonce();
        interface Ieee154LocalAddressProvider as LoWPANLinkLayerAddressProvider @exactlyonce();
        interface LoWPANIPv6PacketForwarder @exactlyonce();
        interface LoWPANIPv6PacketAcceptor @exactlyonce();
        interface LoWPANSimpleRoutingStrategy @atmostonce();
        interface LoWPANDropPacket @atmostonce();
        interface SynchronousStarter as LoWPANAdditionalStarter;
        interface ObjectAllocator<whip6_ipv6_in_packet_processing_state_t> as IncomingPacketStateAllocator @exactlyonce();
    }
}
implementation
{
    enum
    {
        MAX_NUM_UNICAST_ADDRS = max_num_unicast_addrs,
        MAX_NUM_MULTICAST_ADDRS = max_num_multicast_addrs,
    };

    enum
    {
        MAX_CONCURRENT_PACKETS = max_num_concurr_packets,
    };

    components new LoWPANIPv6InterfaceStateManagerPrv(
            MAX_NUM_UNICAST_ADDRS,
            MAX_NUM_MULTICAST_ADDRS
    ) as IfaceStateManagerPrv;
    components new GenericSimpleRoutingLoWPANInterfaceAdapterMainPrv(
    ) as MainPrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            MAX_CONCURRENT_PACKETS,
            "AddressSelectorQueuePrv"
    ) as AddressSelectorQueuePrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            MAX_CONCURRENT_PACKETS,
            "RouterQueuePrv"
    ) as RouterQueuePrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            MAX_CONCURRENT_PACKETS,
            "ForwarderQueuePrv"
    ) as ForwarderQueuePrv;

    Init = MainPrv.Init;
    SynchronousStarter = MainPrv.SynchronousStarter;
    IPv6PacketSourceAddressSelector = MainPrv.IPv6PacketSourceAddressSelector;
    IPv6PacketSender = MainPrv.IPv6PacketSender;
    IPv6PacketReceiver = MainPrv.IPv6PacketReceiver;
    IPv6InterfaceStateProvider = IfaceStateManagerPrv.GenericIPv6InterfaceStateProvider;
    IPv6InterfaceStateUpdater = IfaceStateManagerPrv.GenericIPv6InterfaceStateUpdater;
    
    MainPrv.LoWPANIfaceStateManagerInit -> IfaceStateManagerPrv;
    MainPrv.LoWPANStackStarter = LoWPANStackStarter;
    MainPrv.LoWPANIfaceStateManagerStarter -> IfaceStateManagerPrv;
    MainPrv.LoWPANLinkLayerAddressProvider = LoWPANLinkLayerAddressProvider;
    MainPrv.IPv6InterfaceStateProvider -> IfaceStateManagerPrv.GenericIPv6InterfaceStateProvider;
    MainPrv.LoWPANSimpleRoutingStrategy = LoWPANSimpleRoutingStrategy;
    MainPrv.LoWPANDropPacket = LoWPANDropPacket;
    MainPrv.LoWPANAdditionalStarter = LoWPANAdditionalStarter;
    MainPrv.LoWPANIPv6PacketForwarder = LoWPANIPv6PacketForwarder;
    MainPrv.LoWPANIPv6PacketAcceptor = LoWPANIPv6PacketAcceptor;
    MainPrv.AddressSelectorQueue -> AddressSelectorQueuePrv;
    MainPrv.RouterQueue -> RouterQueuePrv;
    MainPrv.ForwarderQueue -> ForwarderQueuePrv;
    MainPrv.DeliveryAllocator = IncomingPacketStateAllocator;

    IfaceStateManagerPrv.Ieee154LocalAddressProvider = LoWPANLinkLayerAddressProvider;
}

