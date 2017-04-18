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
 * The main module of the network-layer forwarder
 * for incoming packets.
 *
 * @author Konrad Iwanicki
 */
generic module IPv6IncomingPacketForwarderMainPrv()
{
    uses
    {
        interface IPv6PacketReceiver as PacketReceiver @exactlyonce();
        interface IPv6PacketSender as PacketSender @exactlyonce();
        interface Queue<whip6_ipv6_in_packet_processing_state_t *, uint8_t> as ForwardedPacketQueue @atleastonce();
        interface Bit as ForwardingInProgressBit @atleastonce();
    }
}
implementation
{

// #define local_dbg(...) printf(__VA_ARGS__)
#define local_dbg(...)

// #define local_assert(cond) do { if (!(cond)) { uint8_t ___XXX_Assert = 5; printf("Assertion " #cond " failed in file \"%s\", line %u!", __FILE__, __LINE__); while (TRUE) { --___XXX_Assert; }; } } while (0);
#define local_assert(cond)


    whip6_ipv6_out_packet_processing_state_t   m_outPacketState;
    error_t                                    m_forwardingStatus;



    static error_t startForwardingIncomingPacket(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    );
    task void startForwardingQueuedPacketTask();
    task void finishForwardingQueuedPacketTask();



    event error_t PacketReceiver.startReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        local_dbg("[IPv6:InPacketForwarder] Trying to start forwarding "
            "packet %lu that corresponds to incoming packet state %lu.\r\n",
            (long unsigned)inPacket->packet, (long unsigned)inPacket);

        if (call ForwardedPacketQueue.isFull())
        {
            local_dbg("[IPv6:InPacketForwarder] The forwarding queue is "
                "full. Unable to forward packet %lu that corresponds to "
                "incoming packet state %lu.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket);

            return ENOMEM;
        }

        call ForwardedPacketQueue.enqueueLast(inPacket);

        if (call ForwardingInProgressBit.isClear())
        {
            post startForwardingQueuedPacketTask();
        }

        local_dbg("[IPv6:InPacketForwarder] Forwarding of packet %lu that "
            "corresponds to incoming packet state %lu started successfully.\r\n",
            (long unsigned)inPacket->packet, (long unsigned)inPacket);

        return SUCCESS;
    }



    static inline error_t startForwardingIncomingPacket(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        m_outPacketState.packet = inPacket->packet;
        m_outPacketState.flags = (
                WHIP6_IPV6_OUT_PACKET_PROCESSING_STATE_FLAG_HAS_SOURCE_ADDRESS |
                0
        );
        m_outPacketState.ifaceId = 0;

        local_dbg("[IPv6:InPacketForwarder] Passing packet %lu that  "
            "corresponds to incoming packet state %lu and outgoing packet "
            "state %lu to the routing subsystem.\r\n",
            (long unsigned)inPacket->packet, (long unsigned)inPacket,
            (long unsigned)&m_outPacketState);

        return call PacketSender.startSendingIPv6Packet(&m_outPacketState);
    }



    task void startForwardingQueuedPacketTask()
    {
        whip6_ipv6_in_packet_processing_state_t *   inPacket;
        error_t                                     status;

        if (call ForwardedPacketQueue.isEmpty() ||
                call ForwardingInProgressBit.isSet())
        {
            local_dbg("[IPv6:InPacketForwarder] No forwarding can be done "
                "at the moment. Waiting...\r\n");

            return;
        }
        inPacket = call ForwardedPacketQueue.peekFirst();
        status = startForwardingIncomingPacket(inPacket);
        if (status == SUCCESS)
        {
            local_dbg("[IPv6:InPacketForwarder] The routing subsystem accepted "
                "packet %lu that corresponds to incoming packet state %lu "
                "and outgoing packet state %lu.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket,
                (long unsigned)&m_outPacketState);

            call ForwardingInProgressBit.set();
        }
        else
        {
            local_dbg("[IPv6:InPacketForwarder] The routing subsystem rejected "
                "packet %lu that corresponds to incoming packet state %lu "
                "and outgoing packet state %lu with status %u. "
                "Finishing the forwarding of the packet.\r\n",
                (long unsigned)inPacket->packet, (long unsigned)inPacket,
                (long unsigned)&m_outPacketState, (unsigned)status);

            call ForwardedPacketQueue.dequeueFirst();
            post startForwardingQueuedPacketTask();
            call PacketReceiver.finishReceivingIPv6Packet(inPacket, status);
        }
    }



    event void PacketSender.finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    )
    {
        whip6_ipv6_in_packet_processing_state_t * inPacket;

        local_assert(outPacket == &m_outPacketState);
        local_assert(!call ForwardedPacketQueue.isEmpty());

        inPacket = call ForwardedPacketQueue.peekFirst();


        whip6_iovIteratorInvalidate(&inPacket->payloadIter);
        inPacket->nextHeaderId = WHIP6_IANA_IPV6_NO_NEXT_HEADER;

        local_assert(outPacket->packet == inPacket->packet);

        local_dbg("[IPv6:InPacketForwarder] The routing subsystem finished "
            "handling packet %lu that corresponds to outgoing packet "
            "state %lu and incoming packet state %lu with status %u.\r\n",
            (long unsigned)outPacket->packet, (long unsigned)outPacket,
            (long unsigned)inPacket, (unsigned)status);

        m_forwardingStatus = status;

        post finishForwardingQueuedPacketTask();
    }



    task void finishForwardingQueuedPacketTask()
    {
        whip6_ipv6_in_packet_processing_state_t * inPacket;

        local_assert(! call ForwardedPacketQueue.isEmpty());
        local_assert(call ForwardingInProgressBit.isSet());

        inPacket = call ForwardedPacketQueue.peekFirst();

        call ForwardingInProgressBit.clear();
        call ForwardedPacketQueue.dequeueFirst();
        post startForwardingQueuedPacketTask();

        local_dbg("[IPv6:InPacketForwarder] Finishing forwarding "
            "packet %lu that corresponds to incoming packet state %lu "
            "with status %u.\r\n", (long unsigned)inPacket->packet,
            (long unsigned)inPacket, (unsigned)m_forwardingStatus);

        call PacketReceiver.finishReceivingIPv6Packet(
                inPacket,
                m_forwardingStatus
        );
    }

#undef local_assert
#undef local_dbg
}
