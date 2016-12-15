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
#include <ipv6/ucIpv6HeaderProcessorTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * The main module implementing the routing
 * policy for outgoing IPv6 packets.
 *
 * The goal of the module is essentially
 * dispatching packets to appropriate
 * network interfaces.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6DefaultPacketRoutingPolicyMainPrv()
{
    provides
    {
        interface IPv6PacketSender as PacketSender;
        interface IPv6PacketSourceAddressSelector as PacketSourceAddressSelector;
    }
    uses
    {
        interface IPv6PacketSender as SubPacketSender[ipv6_net_iface_id_t ifaceId];
        interface IPv6PacketSourceAddressSelector as SubPacketSourceAddressSelector[ipv6_net_iface_id_t ifaceId];
        interface IPv6InterfaceStateProvider as SubInterfaceStateProvider[ipv6_net_iface_id_t ifaceId];
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as RoutedPacketQueue;
        interface ConfigValue<bool> as FailOnFirstErrorOtherThanNoRoute;
    }
}
implementation
{
// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)


    uint8_t findQueueIndexOfRoutedPacket(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    );
    void finishHandlingRoutedPacket(uint8_t idx, error_t status);

    task void routeOutstandingPacketsTask();


    command error_t PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        ipv6_net_iface_id_t   iface;
        error_t               status;

        local_dbg("[IPv6:MainRoutPolicy] Trying to initiate a selection of "
            "the source address for an outgoing packet state, %lu, "
            "corresponding to packet %lu.\r\n", (long unsigned)outPacket,
            (long unsigned)outPacket->packet);

        local_assert((outPacket->flags & (WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED | WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS)) == 0);
        local_assert(!whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&outPacket->packet->header)));
        // local_assert(whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)));
        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0);
        local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ORIGINATING) != 0);
        
        if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) != 0)
        {
            iface = outPacket->ifaceId;
            local_dbg("[IPv6:MainRoutPolicy] The outgoing packet state, %lu, "
                "already has an interface, %u, assigned, and hence, trying "
                "to initiate address selection on the interface.\r\n",
                (long unsigned)outPacket, (unsigned)iface);
            local_assert(call SubInterfaceStateProvider.getInterfaceStatePtr[iface]() != NULL);
            status = call SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[iface](outPacket);
            local_dbg("[IPv6:MainRoutPolicy] An address selection on interface "
                "%u for the outgoing packet state, %lu, %s been initiated.\r\n",
                (unsigned)iface, (long unsigned)outPacket, status == SUCCESS ?
                    "has" : "has NOT");
            return status;
        }
        else
        {
            local_dbg("[IPv6:MainRoutPolicy] The outgoing packet state, %lu, "
                "does not have an interface assigned.\r\n", (long unsigned)outPacket);
            iface = 0;
            while (call SubInterfaceStateProvider.getInterfaceStatePtr[iface]() != NULL)
            {
                status = call SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[iface](outPacket);
                if (status == SUCCESS)
                {
                    local_dbg("[IPv6:MainRoutPolicy] An address selection on interface "
                        "%u for the outgoing packet state, %lu, has been initiated successfully.\r\n",
                        (unsigned)iface, (long unsigned)outPacket);
                    return SUCCESS;
                }
                else if (call FailOnFirstErrorOtherThanNoRoute.get() && status != ENOROUTE)
                {
                    local_dbg("[IPv6:MainRoutPolicy] An address selection on interface "
                        "%u for the outgoing packet state, %lu, has failed to be "
                        "initiated with error %u.\r\n", (unsigned)iface,
                        (long unsigned)outPacket, (unsigned)status);
                    return status;
                }
                else
                {
                    ++iface;
                }
            }
            local_dbg("[IPv6:MainRoutPolicy] Failed to initiate a source address "
                "selection for the outgoing packet state, %lu, on any "
                "interface.\r\n", (long unsigned)outPacket);
            return ENOROUTE;
        }
    }



    event void SubPacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[ipv6_net_iface_id_t iface](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        if (status == SUCCESS)
        {
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) != 0);
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) != 0);
            local_assert(!whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)));

            outPacket->ifaceId = iface;

            local_dbg("[IPv6:MainRoutPolicy] Successfully selected the source "
                "address for the outgoing packet state, %lu, on interface %u.\r\n",
                (long unsigned)outPacket, (unsigned)iface);
        }
        else if (call FailOnFirstErrorOtherThanNoRoute.get() && status != ENOROUTE)
        {
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0);
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) == 0);
            // local_assert(whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)));

            local_dbg("[IPv6:MainRoutPolicy] Failed with error %u when "
                "selecting the source address for the outgoing packet "
                "state, %lu, on interface %u.\r\n", (unsigned)status,
                (long unsigned)outPacket, (unsigned)iface);
        }
        else
        {
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0);
            local_assert((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) == 0);
            // local_assert(whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)));

            ++iface;
            while (call SubInterfaceStateProvider.getInterfaceStatePtr[iface]() != NULL)
            {
                status = call SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[iface](outPacket);
                if (status == SUCCESS)
                {
                    return;
                }
                else if (call FailOnFirstErrorOtherThanNoRoute.get() && status != ENOROUTE)
                {
                    break;
                }
                ++iface;
            }

            local_dbg("[IPv6:MainRoutPolicy] Failed to select "
                "the source address for the outgoing packet "
                "state, %lu, on any interface.\r\n", (unsigned)status,
                (long unsigned)outPacket);

        }
        // Distinguish between packet for which
        // the source address is to be selected
        // internally (when routing) from a packet
        // for which the selection is to be done
        // externally (e.g., by higher layers).
        if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS) != 0)
        {
            outPacket->flags &= ~(uint8_t)WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS;
            post routeOutstandingPacketsTask();
        }
        else
        {
            signal PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(outPacket, status);
        }
    }



    command error_t PacketSender.startSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        error_t status;

        local_dbg("[IPv6:MainRoutPolicy] Starting to process an outgoing packet "
            "state, %lu, corresponding to packet %lu.\r\n",
            (long unsigned)outPacket, (long unsigned)outPacket->packet);
        local_assert((outPacket->flags & (WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED | WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS)) == 0);
        local_assert(!whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&outPacket->packet->header)));

        if (call RoutedPacketQueue.isFull())
        {
            local_dbg("[IPv6:MainRoutPolicy] No queue space for processing the "
                "outgoing packet state, %lu.\r\n", (long unsigned)outPacket);
            return ENOMEM;
        }
        if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) == 0)
        {
            outPacket->ifaceId = 0;
        }
        if (!whip6_ipv6AddrIsUndefined(whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&outPacket->packet->header)))
        {
            outPacket->flags |= WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS;
        }
        if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) != 0)
        {
            local_dbg("[IPv6:MainRoutPolicy] Sending the outgoing packet state, %lu, "
                "has been started successfully.\r\n", (long unsigned)outPacket);
            call RoutedPacketQueue.enqueueLast(outPacket);
            post routeOutstandingPacketsTask();
            return SUCCESS;
        }
        local_dbg("[IPv6:MainRoutPolicy] The outgoing packet state, %lu, "
            "necessitates source address selection.\r\n", (long unsigned)outPacket);
        status =
                call PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
                        outPacket
                );
        if (status == SUCCESS)
        {
            local_dbg("[IPv6:MainRoutPolicy] Successfully initiated source address "
                "selection for the outgoing packet state, %lu.\r\n", (long unsigned)outPacket);
            outPacket->flags |= WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS;
            call RoutedPacketQueue.enqueueLast(outPacket);
            return SUCCESS;
        }
        local_dbg("[IPv6:MainRoutPolicy] Failed to initiate source address "
            "selection for the outgoing packet state, %lu, and hence, failed "
            "to initiate sending of the corresponding packet.\r\n", (long unsigned)outPacket);
        return status;
    }



    task void routeOutstandingPacketsTask()
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;
        uint8_t                                      i, n;
        ipv6_net_iface_id_t                          iface;
        error_t                                      status;
        
        for (i = 0, n = call RoutedPacketQueue.getSize(); i < n; ++i)
        {
            outPacket = call RoutedPacketQueue.peekIth(i);
            if ((outPacket->flags & (
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED |
                        WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ASSIGNED_SOURCE_ADDRESS)) == 0)
            {
                post routeOutstandingPacketsTask();

                if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS) == 0)
                {
                    local_dbg("[IPv6:MainRoutPolicy] Aborting the sending of "
                        "packet %lu, which corresponds to outgoing packet "
                        "state %lu, as it was impossible to obtain the source "
                        "address for the packet.\r\n",
                        (long unsigned)outPacket->packet,
                        (long unsigned)outPacket);

                    finishHandlingRoutedPacket(i, ENOROUTE);
                    return;
                }

                iface = outPacket->ifaceId;

                local_dbg("[IPv6:MainRoutPolicy] Trying to initiate the "
                    "sending of packet %lu, which corresponds to outgoing "
                    "packet state %lu, over interface %u.\r\n",
                    (long unsigned)outPacket->packet,
                    (long unsigned)outPacket, (unsigned)iface);

                if (call SubInterfaceStateProvider.getInterfaceStatePtr[iface]() == NULL)
                {
                    local_dbg("[IPv6:MainRoutPolicy] Aborting the sending of "
                        "packet %lu, which corresponds to outgoing packet "
                        "state %lu, as it was impossible to find an interface "
                        "over which the packet could have been routed.\r\n",
                        (long unsigned)outPacket->packet,
                        (long unsigned)outPacket);

                    finishHandlingRoutedPacket(i, ENOROUTE);
                    return;
                }

                status = call SubPacketSender.startSendingIPv6Packet[iface](outPacket);

                if (status == SUCCESS)
                {
                    local_dbg("[IPv6:MainRoutPolicy] The sending of packet %lu, "
                        "which corresponds to outgoing packet state %lu, "
                        "has been initiated successfully over interface %u.\r\n",
                        (long unsigned)outPacket->packet,
                        (long unsigned)outPacket, (unsigned)iface);

                    outPacket->flags |=
                            WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED;
                }
                else
                {
                    local_dbg("[IPv6:MainRoutPolicy] The sending of packet %lu, "
                        "which corresponds to outgoing packet state %lu, "
                        "has failed to be initiated over interface %u.\r\n",
                        (long unsigned)outPacket->packet,
                        (long unsigned)outPacket, (unsigned)iface);

                    if (status == ENOSYS ||
                            (outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) != 0 ||
                            (call FailOnFirstErrorOtherThanNoRoute.get() && status != ENOROUTE))
                    {
                        local_dbg("[IPv6:MainRoutPolicy] Aborting the sending of "
                            "packet %lu, which corresponds to outgoing packet "
                            "state %lu, as the packet was either bound to the "
                            "interface or the error was critical.\r\n",
                            (long unsigned)outPacket->packet,
                            (long unsigned)outPacket);

                        finishHandlingRoutedPacket(i, status);
                    }
                    else
                    {
                        local_dbg("[IPv6:MainRoutPolicy] Another routing attempt "
                            "will be made for packet %lu, which corresponds "
                            "to outgoing packet state %lu.\r\n",
                            (long unsigned)outPacket->packet,
                            (long unsigned)outPacket);

                        outPacket->ifaceId = iface + 1;
                    }
                }
                return;
            }
        }
        local_dbg("[IPv6:MainRoutPolicy] No routable packets exist.\r\n");
    }



    event void SubPacketSender.finishSendingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        uint8_t   idx;

        local_dbg("[IPv6:MainRoutPolicy] The sending of packet %lu, "
            "which corresponds to outgoing packet state %lu, "
            "has completed over interface %u with status %u.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket,
            (unsigned)ifaceId, (unsigned)status);

        if (status == SUCCESS)
        {
            goto FINISH_PACKET_ROUTING;
        }
        else if ((outPacket->flags & WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_ASSIGNED_TO_IFACE) != 0 ||
                    (call FailOnFirstErrorOtherThanNoRoute.get() && status != ENOROUTE))
        {
            goto FINISH_PACKET_ROUTING;
        }
        else
        {
            outPacket->flags &=
                    ~(uint8_t)WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED;
            outPacket->ifaceId = ifaceId + 1;
            post routeOutstandingPacketsTask();

            return;
        }

    FINISH_PACKET_ROUTING:
        idx = findQueueIndexOfRoutedPacket(outPacket);
        if (idx >= call RoutedPacketQueue.getSize())
        {
            return;
        }
        outPacket->flags &=
                ~(uint8_t)WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_BEING_ROUTED;
        local_dbg("[IPv6:MainRoutPolicy] The sending of packet %lu, "
            "which corresponds to outgoing packet state %lu, "
            "has finished %s.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket,
            status == SUCCESS ? "successfully" : "with a failure");
        finishHandlingRoutedPacket(idx, status);
    }



    uint8_t findQueueIndexOfRoutedPacket(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        uint8_t const   n = call RoutedPacketQueue.getSize();
        uint8_t         i;
        for (i = 0; i < n; ++i)
        {
            if (call RoutedPacketQueue.peekIth(i) == outPacket)
            {
                return i;
            }
        }
        return n;
    }



    void finishHandlingRoutedPacket(uint8_t idx, error_t status)
    {
        whip6_ipv6_out_packet_processing_state_t *   outPacket;

        outPacket = call RoutedPacketQueue.peekIth(idx);
        call RoutedPacketQueue.dequeueIth(idx);
        signal PacketSender.finishSendingIPv6Packet(outPacket, status);
    }



    default command inline error_t SubPacketSender.startSendingIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        return ENOSYS;
    }



    default command inline error_t SubPacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[ipv6_net_iface_id_t ifaceId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        return ENOROUTE;
    }



    default command inline whip6_ipv6_net_iface_generic_state_t * SubInterfaceStateProvider.getInterfaceStatePtr[ipv6_net_iface_id_t ifaceId]()
    {
        return NULL;
    }



    default command inline bool FailOnFirstErrorOtherThanNoRoute.get()
    {
        return TRUE;
    }

#undef local_dbg
#undef local_assert
}

