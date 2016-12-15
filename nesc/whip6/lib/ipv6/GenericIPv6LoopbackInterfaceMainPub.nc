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
 * A generic IPv6 loopback interface.
 *
 * @param packet_queue_length The length of the packet
 *   queue for the interface.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericIPv6LoopbackInterfaceMainPub(
        uint8_t packet_queue_length
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
        interface IPv6PacketCloner as DedicatedPacketCloner;
    }
}
implementation
{

    enum
    {
        PACKET_QUEUE_LENGTH = packet_queue_length,
    };

    components new GenericIPv6LoopbackInterfaceMainPrv() as MainPrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            PACKET_QUEUE_LENGTH,
            "AddressSelectorQueuePrv"
    ) as AddressSelectorQueuePrv;
    components new WatchedQueuePub(
            whip6_ipv6_out_packet_processing_state_t *,
            uint8_t,
            PACKET_QUEUE_LENGTH,
            "PacketClonerQueuePrv"
    ) as PacketClonerQueuePrv;
    components new WatchedQueuePub(
            whip6_ipv6_packet_t *,
            uint8_t,
            PACKET_QUEUE_LENGTH,
            "PacketDeliveryQueuePrv"
    ) as PacketDeliveryQueuePrv;
    components new BitPub() as PacketBeingClonedBitPrv;
    components new BitPub() as PacketBeingDeliveredBitPrv;

    Init = MainPrv;
    SynchronousStarter = MainPrv;
    IPv6PacketSourceAddressSelector = MainPrv;
    IPv6PacketSender = MainPrv;
    IPv6PacketReceiver = MainPrv;
    IPv6InterfaceStateProvider = MainPrv;
    IPv6InterfaceStateUpdater = MainPrv;

    MainPrv.AddressSelectorQueue -> AddressSelectorQueuePrv;
    MainPrv.PacketClonerQueue -> PacketClonerQueuePrv;
    MainPrv.PacketDeliveryQueue -> PacketDeliveryQueuePrv;
    MainPrv.PacketBeingClonedBit -> PacketBeingClonedBitPrv;
    MainPrv.PacketBeingDeliveredBit -> PacketBeingDeliveredBitPrv;
    MainPrv.DedicatedPacketCloner = DedicatedPacketCloner;
}

