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

#include <NetStackCompileTimeConfig.h>
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * An abstraction layer over the implementation
 * of the IPv6 stack.
 *
 * @author Konrad Iwanicki
 */
configuration InternalIPv6StackPub
{
    provides
    {
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
        // not forwarded.
        interface IPv6PacketReceiver as HopByHopRoutingLoopIn[ipv6_next_header_field_t nxtHdrId];
    }
}
implementation
{
    components CoreIPv6StackPrv as ImplPrv;

    SynchronousStarter = ImplPrv.SynchronousStarter;
    PacketSourceAddressSelector = ImplPrv.PacketSourceAddressSelector;
    PacketSender = ImplPrv.PacketSender;
    PacketReceiver = ImplPrv.PacketReceiver;
    HopByHopRoutingLoopOut = ImplPrv.HopByHopRoutingLoopOut;

    ImplPrv.InterfaceInit = InterfaceInit;
    ImplPrv.InterfaceStarter = InterfaceStarter;
    ImplPrv.InterfaceStateProvider = InterfaceStateProvider;
    ImplPrv.InterfacePacketSourceAddressSelector = InterfacePacketSourceAddressSelector;
    ImplPrv.InterfacePacketSender = InterfacePacketSender;
    ImplPrv.InterfacePacketReceiver = InterfacePacketReceiver;
    ImplPrv.OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol = OptionalOutgoingPacketSourceAddressSelectorQueueForProtocol;
    ImplPrv.OptionalOutgoingPacketSenderQueueForProtocol = OptionalOutgoingPacketSenderQueueForProtocol;
    ImplPrv.HopByHopRoutingLoopIn = HopByHopRoutingLoopIn;

    // IPv6 interfaces.
    components IPv6InterfaceStateProviderPub;

    // Various address printfing.
    components AddressPrintingPub;
}

