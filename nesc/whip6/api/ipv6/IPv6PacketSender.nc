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



/**
 * A sender for IPv6 packets.
 *
 * @see IPv6PacketSourceAddressSelector
 * @see IPv6PacketReceiver
 *
 * @author Konrad Iwanicki
 */
interface IPv6PacketSender
{
    /**
     * Initiates sending an IPv6 packet.
     * @param outPacket A pointer to the processing state
     *   for the packet to be sent.
     * @return SUCCESS if sending was initiated
     *   successfully, in which case the implementer
     *   takes over the ownership of the state and
     *   guarantees to signal the end of sending;
     *   or an error code otherwise, in which case
     *   the ownership of the state stays with the
     *   caller and no end of sending will be signaled.
     */
    command error_t startSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    );

    /**
     * Signaled to notify that sending an
     * IPv6 packet has finished.
     * @param outPacket A pointer to the processing state
     *   of the packet whose sending has finished. The
     *   ownership of the state is transferred to the
     *   implementer.
     * @param status The result of sending the packet.
     */
    event void finishSendingIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    );
}

