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
 * A receiver for IPv6 packets.
 *
 * @see IPv6PacketSender
 *
 * @author Konrad Iwanicki
 */
interface IPv6PacketReceiver
{
    /**
     * Signaled when an IPv6 packet has
     * arrived at the present node and should
     * be processed by the node.
     * @param inPacket A pointer to the processing
     *   state of the incoming packet.
     * @return SUCCESS if receiving the packet started
     *   successfully, in which case the
     *   <tt>finishReceivingIPv6Packet</tt> event is
     *   guaranteed to be invoked; or an error code
     *   otherwise, in which case no 
     *   <tt>finishReceivingIPv6Packet</tt> event
     *   will be invoked.
     */
    event error_t startReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket
    );

    /**
     * Invoked to notify that receiving the
     * previous IPv6 packet has finished.
     * @param inPacket A pointer to the processing
     *   state of the incoming packet whose processing
     *   has finished.
     * @param status The status of the reception.
     */
    command void finishReceivingIPv6Packet(
            whip6_ipv6_in_packet_processing_state_t * inPacket,
            error_t status
    );
}

