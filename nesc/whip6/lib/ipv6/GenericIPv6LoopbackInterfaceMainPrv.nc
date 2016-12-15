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

#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>
#include <ipv6/ucIpv6PacketAllocation.h>
#include <ipv6/ucIpv6PacketTypes.h>


/**
 * The main module of an IPv6 loopback interface.
 *
 * @author Konrad Iwanicki
 */
generic module GenericIPv6LoopbackInterfaceMainPrv()
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
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as AddressSelectorQueue;
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as PacketClonerQueue;
        interface Queue<whip6_ipv6_packet_t *, uint8_t> as PacketDeliveryQueue;
        interface Bit as PacketBeingClonedBit;
        interface Bit as PacketBeingDeliveredBit;
        interface IPv6PacketCloner as DedicatedPacketCloner;
    }
}
implementation
{
// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)



    whip6_ipv6_net_iface_generic_state_t      m_ifaceState;
    whip6_ipv6_in_packet_processing_state_t   m_inPacketStateBuf;



    task void completeAddressSelectionTask();
    task void startPacketCloningTask();
    task void deliverPacketCloneTask();



    command inline error_t Init.init()
    {
        whip6_ipv6InterfaceSetType(&m_ifaceState, WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_LOOPBACK);
        whip6_ipv6InterfaceSetUnicastAddrArray(&m_ifaceState, NULL, 0);
        whip6_ipv6InterfaceSetMulticastAddrArray(&m_ifaceState, NULL, 0);
        return SUCCESS;
    }



    command inline error_t SynchronousStarter.start()
    {
        if (whip6_ipv6InterfaceHasOnFlag(&m_ifaceState))
        {
            return EALREADY;
        }
        whip6_ipv6InterfaceSetOnFlag(&m_ifaceState);
        return SUCCESS;
    }



    command error_t IPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        whip6_ipv6_addr_t const *   dstAddr;
        whip6_ipv6_addr_t *         srcAddr;

        if (!whip6_ipv6InterfaceHasOnFlag(&m_ifaceState))
        {
            return EOFF;
        }

        local_dbg("[IPv6:Loopback] Starting to select the source address for "
            "an outgoing packet state, %lu, corresponding to packet %lu.\r\n",
            (long unsigned)outPacket, (long unsigned)outPacket->packet);

        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING) != 0);
        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0);

        dstAddr =
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                        &outPacket->packet->header
                );
        if (!whip6_ipv6AddrIsLoopback(dstAddr))
        {
            local_dbg("[IPv6:Loopback] The destination address for the "
                "outgoing packet state, %lu, is not a loopback address, "
                "so the source address cannot be a loopback one.\r\n",
                (long unsigned)outPacket);

            return ENOROUTE;
        }
        if (call AddressSelectorQueue.isFull())
        {
            local_dbg("[IPv6:Loopback] No queue space to select the source "
                "address for an outgoing packet state, %lu, corresponding "
                "to packet %lu.\r\n", (long unsigned)outPacket,
                (long unsigned)outPacket->packet);

            return ENOMEM;
        }
        srcAddr =
                whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(
                        &outPacket->packet->header
                );
        whip6_ipv6AddrSetLoopbackAddr(srcAddr);
        outPacket->flags |= (
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE |
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS
                );
        call AddressSelectorQueue.enqueueLast(outPacket);
        post completeAddressSelectionTask();

        local_dbg("[IPv6:Loopback] Successfully started selecting the source "
            "address for an outgoing packet state, %lu, corresponding to "
            "packet %lu.\r\n", (long unsigned)outPacket,
            (long unsigned)outPacket->packet);

        return SUCCESS;
    }



    task void completeAddressSelectionTask()
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        if (call AddressSelectorQueue.isEmpty())
        {
            return;
        }
        outPacket = call AddressSelectorQueue.peekFirst();
        call AddressSelectorQueue.dequeueFirst();
        post completeAddressSelectionTask();

        local_dbg("[IPv6:Loopback] Successfully finished selecting the source "
            "address for an outgoing packet state, %lu, corresponding to "
            "packet %lu.\r\n", (long unsigned)outPacket,
            (long unsigned)outPacket->packet);

        signal IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
                outPacket,
                SUCCESS
        );
    }



    command error_t IPv6PacketSender.startSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        if (!whip6_ipv6InterfaceHasOnFlag(&m_ifaceState))
        {
            return EOFF;
        }

        local_dbg("[IPv6:Loopback] Starting to send packet %lu "
            "with an outgoing packet state, %lu.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket);

        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) != 0);

        if (!whip6_ipv6AddrIsLoopback(whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&outPacket->packet->header)))
        {
            local_dbg("[IPv6:Loopback] The outgoing packet state, %lu, "
                "is not destined to a loopback recipient. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return ENOROUTE;
        }
        if (!whip6_ipv6AddrIsLoopback(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)))
        {
            local_dbg("[IPv6:Loopback] The outgoing packet state, %lu, "
                "is not sourced at a loopback interface. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return EINVAL;
        }
        if (call PacketClonerQueue.isFull())
        {
            local_dbg("[IPv6:Loopback] No memory to queue the outgoing packet "
                "state, %lu, for sending. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return ENOMEM;
        }
        outPacket->flags |=
                WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE;
        call PacketClonerQueue.enqueueLast(outPacket);
        post startPacketCloningTask();

        local_dbg("[IPv6:Loopback] Successfully queued the outgoing packet "
            "state, %lu, for sending.\r\n", (long unsigned)outPacket);

        return SUCCESS;
    }



    task void startPacketCloningTask()
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        error_t                                      status;

        if (call PacketClonerQueue.isEmpty() || call PacketBeingClonedBit.isSet())
        {
            return;
        }
        outPacket = call PacketClonerQueue.peekFirst();
        status =
                call DedicatedPacketCloner.startCloningIPv6Packet(
                        outPacket->packet
                );
        if (status == SUCCESS)
        {
            local_dbg("[IPv6:Loopback] Started cloning the outgoing packet "
                "state, %lu, which corresponds to packet %lu.\r\n",
                (long unsigned)outPacket, (long unsigned)outPacket->packet);

            call PacketBeingClonedBit.set();
        }
        else
        {
            local_dbg("[IPv6:Loopback] Failed to start cloning the outgoing "
                "packet state, %lu, which corresponds to packet %lu. "
                "Aborting the sending of the packet.\r\n",
                (long unsigned)outPacket, (long unsigned)outPacket->packet);

            call PacketClonerQueue.dequeueFirst();
            post startPacketCloningTask();
            signal IPv6PacketSender.finishSendingIPv6Packet(outPacket, status);
        }
    }



    event void DedicatedPacketCloner.finishCloningIPv6Packet(
            whip6_ipv6_packet_t const * orgPacket,
            whip6_ipv6_packet_t * clonePacketOrNull
    )
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        error_t                                      status;

        local_assert(! call PacketClonerQueue.isEmpty());
        local_assert(call PacketBeingClonedBit.isSet());

        outPacket = call PacketClonerQueue.peekFirst();
        call PacketClonerQueue.dequeueFirst();
        call PacketBeingClonedBit.clear();
        post startPacketCloningTask();

        local_assert(outPacket->packet == orgPacket);

        if (clonePacketOrNull != NULL)
        {
            local_dbg("[IPv6:Loopback] Successfully cloned the outgoing "
                "packet state, %lu, which corresponds to packet %lu "
                "into packet %lu.\r\n",
                (long unsigned)outPacket, (long unsigned)outPacket->packet,
                (long unsigned)clonePacketOrNull);

            if (call PacketDeliveryQueue.isFull())
            {
                local_dbg("[IPv6:Loopback] No memory to deliver the cloned "
                    "packet, %lu.\r\n", (long unsigned)clonePacketOrNull);

                whip6_ipv6FreePacket(clonePacketOrNull);
                status = ENOMEM;
            }
            else
            {
                local_dbg("[IPv6:Loopback] Queued the cloned packet, %lu, "
                    "for delivery.\r\n", (long unsigned)clonePacketOrNull);

                call PacketDeliveryQueue.enqueueLast(clonePacketOrNull);
                post deliverPacketCloneTask();
                status = SUCCESS;
            }
        }
        else
        {
            local_dbg("[IPv6:Loopback] Failed to clone the outgoing "
                "packet state, %lu, which corresponds to packet %lu.\r\n",
                (long unsigned)outPacket, (long unsigned)outPacket->packet);

            status = ENOMEM;
        }

        local_dbg("[IPv6:Loopback] Completed the sending of the outgoing packet "
            "state, %lu, which corresponds to packet %lu, with status %u.\r\n",
            (long unsigned)outPacket, (long unsigned)outPacket->packet,
            (unsigned)status);

        signal IPv6PacketSender.finishSendingIPv6Packet(outPacket, status);
    }



    task void deliverPacketCloneTask()
    {
        if (call PacketDeliveryQueue.isEmpty() ||
                call PacketBeingDeliveredBit.isSet())
        {
            return;
        }
        m_inPacketStateBuf.packet = call PacketDeliveryQueue.peekFirst();
        // m_inPacketStateBuf.payloadIter;
        // m_inPacketStateBuf.payloadOffset;
        m_inPacketStateBuf.flags = 0;
        // m_inPacketStateBuf.ifaceId;
        // m_inPacketStateBuf.nextHeaderId;
        call PacketDeliveryQueue.dequeueFirst();

        local_dbg("[IPv6:Loopback] Initiating the delivery of incoming "
            "packet state %lu, which corresponds to packet %lu.\r\n",
            (long unsigned)&m_inPacketStateBuf,
            (long unsigned)m_inPacketStateBuf.packet);

        if (signal IPv6PacketReceiver.startReceivingIPv6Packet(&m_inPacketStateBuf) != SUCCESS)
        {
            local_dbg("[IPv6:Loopback] Failed to initiate the delivery of "
                "incoming packet state %lu, which corresponds to packet %lu.\r\n",
                (long unsigned)&m_inPacketStateBuf,
                (long unsigned)m_inPacketStateBuf.packet);

            whip6_ipv6FreePacket(m_inPacketStateBuf.packet);
            post deliverPacketCloneTask();
        }
        else
        {
            local_dbg("[IPv6:Loopback] The delivery of incoming "
                "packet state %lu, which corresponds to packet %lu, "
                "initiated successfully.\r\n",
                (long unsigned)&m_inPacketStateBuf,
                (long unsigned)m_inPacketStateBuf.packet);

            call PacketBeingDeliveredBit.set();
        }
    }



    command void IPv6PacketReceiver.finishReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {
        local_assert(inPacket == &m_inPacketStateBuf);

        local_dbg("[IPv6:Loopback] Finished the delivery of incoming packet "
            "state %lu, which corresponds to packet %lu, with status %u.\r\n",
            (long unsigned)&m_inPacketStateBuf,
            (long unsigned)m_inPacketStateBuf.packet, (unsigned)status);

        if (m_inPacketStateBuf.packet != NULL)
        {
            whip6_ipv6FreePacket(m_inPacketStateBuf.packet);
        }
        call PacketBeingDeliveredBit.clear();
        post deliverPacketCloneTask();
    }



    command inline whip6_ipv6_net_iface_generic_state_t * IPv6InterfaceStateProvider.getInterfaceStatePtr()
    {
        return &m_ifaceState;
    }



    command inline void IPv6InterfaceStateUpdater.clearAssociatedAddresses()
    {
        // NOTICE iwanicki 2013-12-28:
        // No addresses can be associated with
        // the loopback interface.

        // Do nothing.
    }



    command inline whip6_ipv6_addr_t * IPv6InterfaceStateUpdater.addNewUnicastAddressAsLast()
    {
        // NOTICE iwanicki 2013-12-28:
        // No addresses can be associated with
        // the loopback interface.
        return NULL;
    }



    command inline void IPv6InterfaceStateUpdater.compactAssociatedAddresses()
    {
        // NOTICE iwanicki 2013-12-28:
        // No addresses can be associated with
        // the loopback interface.

        // Do nothing.
    }

#undef local_dbg
#undef local_assert
}

