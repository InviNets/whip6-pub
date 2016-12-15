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

#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ieee154/ucIeee154Ipv6InterfaceStateManipulation.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>
#include <ipv6/ucIpv6PacketAllocation.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * The main module of a generic adapter that transforms
 * a 6LoWPAN-compatible stack into an IPv6 network
 * interface with simple routing based on a single fixed
 * default route.
 *
 * @author Konrad Iwanicki
 */
generic module GenericSimpleRoutingLoWPANInterfaceAdapterMainPrv(
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter @atleastonce();
        interface IPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender @exactlyonce();
        interface IPv6PacketReceiver @exactlyonce();
    }
    uses
    {
        interface Init as LoWPANIfaceStateManagerInit @exactlyonce();
        interface SynchronousStarter as LoWPANStackStarter @exactlyonce();
        interface SynchronousStarter as LoWPANIfaceStateManagerStarter @exactlyonce();
        interface SynchronousStarter as LoWPANAdditionalStarter;
        interface Ieee154LocalAddressProvider as LoWPANLinkLayerAddressProvider @exactlyonce();
        interface IPv6InterfaceStateProvider @exactlyonce();
        interface LoWPANSimpleRoutingStrategy @atmostonce();
        interface LoWPANDropPacket @atmostonce();
        interface LoWPANIPv6PacketForwarder @exactlyonce();
        interface LoWPANIPv6PacketAcceptor @exactlyonce();
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as AddressSelectorQueue;
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as RouterQueue;
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as ForwarderQueue;
        interface ObjectAllocator<whip6_ipv6_in_packet_processing_state_t> as DeliveryAllocator;
    }
}
implementation
{
//#define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)


    whip6_ieee154_addr_t   m_llAddrBuf;


    task void completeAddressSelectionTask();
    task void startPacketRoutingTask();



    command inline error_t Init.init()
    {
        error_t status;
        status = call LoWPANIfaceStateManagerInit.init();
        return status;
    }



    command inline error_t SynchronousStarter.start()
    {
        error_t status;

        status = call LoWPANStackStarter.start();
        if (status != SUCCESS && status != EALREADY)
        {
            return status;
        }
        status = call LoWPANIfaceStateManagerStarter.start();
        if (status != SUCCESS && status != EALREADY)
        {
            return status;
        }
        status = call LoWPANAdditionalStarter.start();
        return status;
    }



    command error_t IPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        whip6_ipv6_addr_t const *   dstAddr;
        whip6_ipv6_addr_t *         srcAddr;

        if (! whip6_ipv6InterfaceHasOnFlag(
                    call IPv6InterfaceStateProvider.getInterfaceStatePtr()))
        {
            return EOFF;
        }

        local_dbg("[IPv6:6LoWPAN] Starting to select the source address for "
            "an outgoing packet state, %lu, corresponding to packet %lu.\r\n",
            (long unsigned)outPacket, (long unsigned)outPacket->packet);

        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING) != 0);
        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0);

        dstAddr =
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                        &outPacket->packet->header
                );
        if (whip6_ipv6AddrIsLoopback(dstAddr))
        {
            local_dbg("[IPv6:6LoWPAN] The destination address for the "
                "outgoing packet state, %lu, is a loopback address.\r\n",
                (long unsigned)outPacket);

            return ENOROUTE;
        }
        if (call AddressSelectorQueue.isFull())
        {
            local_dbg("[IPv6:6LoWPAN] No queue space to select the source "
                "address for an outgoing packet state, %lu, corresponding "
                "to packet %lu.\r\n", (long unsigned)outPacket,
                (long unsigned)outPacket->packet);

            return ENOMEM;
        }
        srcAddr =
                whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(
                        &outPacket->packet->header
                );
        if (! whip6_ipv6InterfaceGetBestSrcAddrForDstAddr(
                    call IPv6InterfaceStateProvider.getInterfaceStatePtr(),
                    srcAddr,
                    dstAddr))
        {
            local_dbg("[IPv6:6LoWPAN] No address with the right scope to "
                "select the source address for an outgoing packet state, "
                "%lu, corresponding to packet %lu.\r\n", (long unsigned)outPacket,
                (long unsigned)outPacket->packet);

            return ENOROUTE;
        }
        outPacket->flags |= (
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE |
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS
                );
        call AddressSelectorQueue.enqueueLast(outPacket);
        post completeAddressSelectionTask();

        local_dbg("[IPv6:6LoWPAN] Successfully started selecting the source "
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

        local_dbg("[IPv6:6LoWPAN] Successfully finished selecting the source "
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
        whip6_ipv6_addr_t const *   dstAddr;
        whip6_ipv6_addr_t const *   srcAddr;

        if (! whip6_ipv6InterfaceHasOnFlag(
                    call IPv6InterfaceStateProvider.getInterfaceStatePtr()))
        {
            return EOFF;
        }

        local_dbg("[IPv6:6LoWPAN] Starting to send packet %lu "
            "with an outgoing packet state, %lu.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket);

        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) != 0);

        srcAddr =
                whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                        &outPacket->packet->header
                );
        dstAddr =
                whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                        &outPacket->packet->header
                );
        if (whip6_ipv6AddrIsLoopback(srcAddr))
        {
            local_dbg("[IPv6:6LoWPAN] The outgoing packet state, %lu, "
                "has invalid addresses. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return EINVAL;
        }

        // NOTICE iwanicki 2013-12-28:
        // We deliberately do not implement the loopback
        // functionality here. If such functionality is
        // necessary, it can be used by means of the
        // loopback interface.

        if (whip6_ipv6AddrIsLoopback(dstAddr))
        {
            local_dbg("[IPv6:6LoWPAN] The outgoing packet state, %lu, "
                "is destined to a loopback address. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return ENOROUTE;
        }

        if (call RouterQueue.isFull())
        {
            local_dbg("[IPv6:6LoWPAN] No memory to queue the outgoing packet "
                "state, %lu, for sending. Aborting sending.\r\n",
                (long unsigned)outPacket);

            return ENOMEM;
        }
        
        call RouterQueue.enqueueLast(outPacket);
        post startPacketRoutingTask();

        local_dbg("[IPv6:6LoWPAN] Successfully queued the outgoing packet "
            "state, %lu, for routing.\r\n", (long unsigned)outPacket);

        return SUCCESS;
    }



    task void startPacketRoutingTask()
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        whip6_ipv6_basic_header_t *                  pktHdr;
        whip6_ipv6_addr_t const *                    dstAddr;
        error_t                                      status;

        if (call RouterQueue.isEmpty())
        {
            return;
        }
        outPacket = call RouterQueue.peekFirst();
        call RouterQueue.dequeueFirst();
        post startPacketRoutingTask();

        pktHdr = &outPacket->packet->header;
        dstAddr = whip6_ipv6BasicHeaderGetDstAddrPtrForReading(pktHdr);

        // NOTICE iwanicki 2013-12-28:
        // It is assumed that the destination address
        // has been check externally and that it is
        // not undefined, loopback, or the node's
        // own address.
        
        if (whip6_ipv6AddrIsMulticast(dstAddr))
        {
            // A multicast address.
            if (whip6_ipv6AddrGetScope(dstAddr) == IPV6_ADDRESS_SCOPE_LINK_LOCAL)
            {
                whip6_ieee154AddrAnySetBroadcast(
                        &m_llAddrBuf
                );
                whip6_ipv6BasicHeaderSetHopLimit(pktHdr, 1);
            }
            else
            {
                call LoWPANSimpleRoutingStrategy.pickFirstRouteLinkLayerAddr(
                        outPacket,
                        dstAddr,
                        &m_llAddrBuf);
            }
        }
        else
        {
            // A unicast address.
            if (whip6_ipv6AddrIsLinkLocal(dstAddr))
            {
                whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
                        dstAddr,
                        &m_llAddrBuf,
                        call LoWPANLinkLayerAddressProvider.getPanIdPtr()
                );
                whip6_ipv6BasicHeaderSetHopLimit(pktHdr, 1);
            }
            else
            {
                call LoWPANSimpleRoutingStrategy.pickFirstRouteLinkLayerAddr(
                        outPacket,
                        dstAddr,
                        &m_llAddrBuf);
            }
        }

        if (whip6_ieee154AddrAnyIsNone(&m_llAddrBuf) != 0)
        {
            local_dbg("[IPv6:6LoWPAN] No link-layer address was assigned "
                "to packet %lu with an outgoing packet state, %lu. "
                "Aborting sending.\r\n",
                (long unsigned)outPacket->packet, (long unsigned)outPacket);

            status = ENOROUTE;
            goto FAILURE_ROLLBACK_0;
        }
        
        outPacket->flags |=
                WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE;

        local_dbg("[IPv6:6LoWPAN] Assigned packet %lu with an outgoing "
            "packet state, %lu, to the network interface.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket);

        if (call ForwarderQueue.isFull())
        {
            local_dbg("[IPv6:6LoWPAN] The forwarding queue has no space for "
                "packet %lu with an outgoing packet state, %lu. "
                "Aborting sending.\r\n",
                (long unsigned)outPacket->packet, (long unsigned)outPacket);

            status = ENOMEM;
            goto FAILURE_ROLLBACK_0;
        }

        local_dbg("[IPv6:6LoWPAN] Before: outPacket->flags = %d\n",
                  (int)outPacket->flags);

        status =
                call LoWPANIPv6PacketForwarder.startForwardingIpv6Packet(
                        outPacket->packet,
                        &m_llAddrBuf
                );
        if (status != SUCCESS)
        {
            local_dbg("[IPv6:6LoWPAN] Passing packet %lu with an outgoing "
                "packet state, %lu, to a lower layer has failed. "
                "Aborting sending.\r\n",
                (long unsigned)outPacket->packet, (long unsigned)outPacket);

            goto FAILURE_ROLLBACK_0;
        }

        call ForwarderQueue.enqueueLast(outPacket);

        local_dbg("[IPv6:6LoWPAN] Successfully passed packet %lu with an "
            "outgoing packet state, %lu, to a lower layer.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket);

        return;

    FAILURE_ROLLBACK_0:
        signal IPv6PacketSender.finishSendingIPv6Packet(outPacket, status);
    }



    event void LoWPANIPv6PacketForwarder.forwardingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * llAddr,
            error_t status
    )
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        uint8_t                                      i, n;

        for (i = 0, n = call ForwarderQueue.getSize(); i < n; ++i)
        {
            outPacket = call ForwarderQueue.peekIth(i);
            if (outPacket->packet == packet)
            {
                if (status != SUCCESS)
                {
                    whip6_ipv6_addr_t const *dstAddr =
                        whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                                &outPacket->packet->header);

                    local_dbg("[IPv6:6LoWPAN] Forwarding failed. Refering to routing strategy\n");

                    call LoWPANSimpleRoutingStrategy.pickNextRouteLinkLayerAddr(
                            outPacket,
                            dstAddr,
                            llAddr,
                            status,
                            &m_llAddrBuf);
                    if (whip6_ieee154AddrAnyIsNone(&m_llAddrBuf) == 0)
                    {
                        error_t forwStatus;

                        local_dbg("[IPv6:6LoWPAN] After: outPacket->flags = %d\n",
                                  (int)outPacket->flags);
                        forwStatus =
                            call LoWPANIPv6PacketForwarder.startForwardingIpv6Packet(
                                    outPacket->packet,
                                    &m_llAddrBuf);

                        if (forwStatus == SUCCESS)
                        {
                            return;
                        }
                        else
                        {
                            local_dbg("[IPv6:6LoWPAN] Strategy provided an address, but "
                                    "LoWPANIPv6PacketForwarder faild to start forwarding\n");
                        }

                    }
                }

                call ForwarderQueue.dequeueIth(i);

                local_dbg("[IPv6:6LoWPAN] A lower layer has completed the "
                    "sending of packet %lu with an outgoing packet state, "
                    "%lu, with status %u.\r\n",
                    (long unsigned)outPacket->packet, (long unsigned)outPacket,
                    (unsigned)status);

                signal IPv6PacketSender.finishSendingIPv6Packet(
                        outPacket,
                        status
                );
                return;
            }
        }
    }



    event void LoWPANIPv6PacketAcceptor.acceptedIpv6PacketForProcessing(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr
    )
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;

        local_dbg("[IPv6:6LoWPAN] A lower layer has passed a received "
            "packet %lu.\r\n", (long unsigned)packet);

#ifdef LOWPAN_PRINTF_ASSEMBLED_IPV6_PACKETS
        {
            whip6_ipv6_addr_t const * addr;
            addr = whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(
                    &packet->header
            );
            printf("[6LoWPAN] Assembled IPv6 packet with addresses:\n");
            printf_ipv6(addr);
            printf(" -> ");
            addr = whip6_ipv6BasicHeaderGetDstAddrPtrForReading(
                    &packet->header
            );
            printf_ipv6(addr);
            printf("\n");
        }
#endif  // LOWPAN_PRINTF_ASSEMBLED_IPV6_PACKETS

        if (call LoWPANDropPacket.shouldDropPacket(packet,
                    whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&packet->header),
                    whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&packet->header))) {
            local_dbg("[IPv6:6LoWPAN] LoWPANDropPacket orderd packet drop.\r\n");
            goto FAILURE_ROLLBACK_0;
        }

        inPacket = call DeliveryAllocator.allocate();
        if (inPacket == NULL)
        {
            local_dbg("[IPv6:6LoWPAN] DeliveryAllocator faild to allocate an incoming "
                      "packet state. Dropping packet.\r\n");
            goto FAILURE_ROLLBACK_0;
        }
        inPacket->packet = packet;
        inPacket->flags = 0;

        local_dbg("[IPv6:6LoWPAN] Allocated an incoming packet state, %lu, "
            "for the received packet, %lu. Initiating the reception.\r\n",
            (long unsigned)inPacket, (long unsigned)inPacket->packet);

        if (signal IPv6PacketReceiver.startReceivingIPv6Packet(inPacket) != SUCCESS)
        {
            local_dbg("[IPv6:6LoWPAN] Failed to initiate the reception of "
                "incoming packet state %lu, which corresponds to packet %lu.\r\n",
                (long unsigned)inPacket, (long unsigned)inPacket->packet);

            goto FAILURE_ROLLBACK_1;
        }

        local_dbg("[IPv6:6LoWPAN] Successfully initiated the reception of "
            "incoming packet state %lu, which corresponds to packet %lu.\r\n",
            (long unsigned)inPacket, (long unsigned)inPacket->packet);

        return;

    FAILURE_ROLLBACK_1:
        call DeliveryAllocator.free(inPacket);
    FAILURE_ROLLBACK_0:
        whip6_ipv6FreePacket(packet);
    }



    command void IPv6PacketReceiver.finishReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    )
    {        
        local_dbg("[IPv6:6LoWPAN] Finished the reception of incoming "
            "packet state %lu, which corresponds to packet %lu, with "
            "status %u.\r\n", (long unsigned)inPacket,
            (long unsigned)inPacket->packet, (unsigned)status);

        if (inPacket->packet != NULL)
        {
            whip6_ipv6FreePacket(inPacket->packet);
        }
        call DeliveryAllocator.free(inPacket);
    }


    default command inline error_t LoWPANAdditionalStarter.start()
    {
        return SUCCESS;
    }

    default command bool LoWPANDropPacket.shouldDropPacket(
            whip6_ipv6_packet_t *packet,
            whip6_ipv6_addr_t const *srcAddr,
            whip6_ipv6_addr_t const *dstAddr) {
        return FALSE;
    }


#undef local_dbg
#undef local_assert
}

