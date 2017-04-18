/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6HeaderProcessorTypes.h>



/**
 * A virtualizer for outgoing IPv6 packets.
 *
 * @param num_clients The number of clients.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6OutgoingPacketStackVirtualizerPrv(
        uint8_t num_clients
)
{
    provides
    {
        interface IPv6PacketSourceAddressSelector[uint8_t clientId] @atmostonce();
        interface IPv6PacketSender[uint8_t clientId] @atmostonce();
    }
    uses
    {
        interface IPv6PacketSourceAddressSelector as SubIPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender as SubIPv6PacketSender @exactlyonce();
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as AddressSelectionQueue[uint8_t clientId];
        interface Queue<whip6_ipv6_out_packet_processing_state_t *, uint8_t> as SendingQueue[uint8_t clientId];
    }
}
implementation
{
    enum
    {
        NUM_CLIENTS = num_clients,
    };

    bool subSenderWorking = FALSE;
    whip6_ipv6_out_packet_processing_state_t *   m_defaultSelectionPacketPtrs[NUM_CLIENTS];
    whip6_ipv6_out_packet_processing_state_t *   m_defaultSendingPacketPtrs[NUM_CLIENTS];


#define LOCAL_FATAL_FAILURE

    command error_t IPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        error_t status = SUCCESS;

        if (clientId >= NUM_CLIENTS)
        {
            return EINVAL;
        }
        if (call AddressSelectionQueue.isFull[clientId]())
        {
            return EBUSY;
        }
        if (call AddressSelectionQueue.isEmpty[clientId]())
        {
            status =
                    call SubIPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
                            outPacket
                    );
        }
        if (status == SUCCESS)
        {
            call AddressSelectionQueue.enqueueLast[clientId](outPacket);
        }
        return status;
    }



    event void SubIPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        uint8_t   clientId;
        bool      nextItem;

        for (clientId = 0; clientId < NUM_CLIENTS; ++clientId)
        {
            if (! call AddressSelectionQueue.isEmpty[clientId]())
            {
                if (call AddressSelectionQueue.peekFirst[clientId]() == outPacket)
                {
                    call AddressSelectionQueue.dequeueFirst[clientId]();
                    nextItem = ! call AddressSelectionQueue.isEmpty[clientId]();
                    signal IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[clientId](
                            outPacket,
                            status
                    );
                    // NOTICE iwanicki 2013-12-27:
                    // The loop below may potentially never end if the user
                    // will keep adding packets while all of these packets
                    // fail. If this turns out to be a problem, we can
                    // split the loop into tasks.
                    while (nextItem)
                    {
                        outPacket = call AddressSelectionQueue.peekFirst[clientId]();
                        status = 
                                call SubIPv6PacketSourceAddressSelector.startSelectingSourceAddressForIPv6Packet(
                                        outPacket
                                );
                        if (status == SUCCESS)
                        {
                            break;
                        }
                        call AddressSelectionQueue.dequeueFirst[clientId]();
                        nextItem = ! call AddressSelectionQueue.isEmpty[clientId]();
                        signal IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[clientId](
                                outPacket,
                                FAIL
                        );
                    }
                    return;
                }
            }
        }
    }



    command error_t IPv6PacketSender.startSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        error_t status = SUCCESS;

        if (clientId >= NUM_CLIENTS)
        {
            return EINVAL;
        }
        if (call SendingQueue.isFull[clientId]())
        {
            return EBUSY;
        }
        if (!subSenderWorking)
        {
            status = call SubIPv6PacketSender.startSendingIPv6Packet(outPacket);
            subSenderWorking = TRUE;
        }
        if (status == SUCCESS)
        {
            call SendingQueue.enqueueLast[clientId](outPacket);
        }
        return status;
    }



    event void SubIPv6PacketSender.finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        uint8_t   clientId;
        subSenderWorking = FALSE;

        for (clientId = 0; clientId < NUM_CLIENTS; ++clientId)
        {
            if (! call SendingQueue.isEmpty[clientId]())
            {
                if (call SendingQueue.peekFirst[clientId]() == outPacket)
                {
                    call SendingQueue.dequeueFirst[clientId]();
                    signal IPv6PacketSender.finishSendingIPv6Packet[clientId](
                            outPacket,
                            status
                    );
                    break;
                }
            }
        }

        for (clientId = 0; clientId < NUM_CLIENTS; ++clientId)
        {
            while (! call SendingQueue.isEmpty[clientId]())
            {
                outPacket = call SendingQueue.peekFirst[clientId]();
                status = call SubIPv6PacketSender.startSendingIPv6Packet(outPacket);
                if (status == SUCCESS)
                {
                    subSenderWorking = TRUE;
                    return;
                }
                call SendingQueue.dequeueFirst[clientId]();
                signal IPv6PacketSender.finishSendingIPv6Packet[clientId](
                        outPacket,
                        FAIL
                        );
            }
        }
    }



    default command inline bool AddressSelectionQueue.isFull[uint8_t clientId]()
    {
        return m_defaultSelectionPacketPtrs[clientId] != NULL;
    }



    default command inline bool AddressSelectionQueue.isEmpty[uint8_t clientId]()
    {
        return m_defaultSelectionPacketPtrs[clientId] == NULL;
    }



    default command inline void AddressSelectionQueue.enqueueLast[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        m_defaultSelectionPacketPtrs[clientId] = outPacket;
    }



    default command inline whip6_ipv6_out_packet_processing_state_t * AddressSelectionQueue.peekFirst[uint8_t clientId]()
    {
        return m_defaultSelectionPacketPtrs[clientId];
    }



    default command inline void AddressSelectionQueue.dequeueFirst[uint8_t clientId]()
    {
        m_defaultSelectionPacketPtrs[clientId] = NULL;
    }



    default command inline bool SendingQueue.isFull[uint8_t clientId]()
    {
        return m_defaultSendingPacketPtrs[clientId] != NULL;
    }



    default command inline bool SendingQueue.isEmpty[uint8_t clientId]()
    {
        return m_defaultSendingPacketPtrs[clientId] == NULL;
    }



    default command inline void SendingQueue.enqueueLast[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket
    )
    {
        m_defaultSendingPacketPtrs[clientId] = outPacket;
    }



    default command inline whip6_ipv6_out_packet_processing_state_t * SendingQueue.peekFirst[uint8_t clientId]()
    {
        return m_defaultSendingPacketPtrs[clientId];
    }



    default command inline void SendingQueue.dequeueFirst[uint8_t clientId]()
    {
        m_defaultSendingPacketPtrs[clientId] = NULL;
    }



    default event inline void IPv6PacketSourceAddressSelector.finishSelectingSourceAddressForIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        LOCAL_FATAL_FAILURE;
    }



    default event inline void IPv6PacketSender.finishSendingIPv6Packet[uint8_t clientId](
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        LOCAL_FATAL_FAILURE;
    }

#undef LOCAL_FATAL_FAILURE
}
