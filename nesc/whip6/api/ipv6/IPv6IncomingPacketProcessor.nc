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
 * A processor of incoming IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
interface IPv6IncomingPacketProcessor
{
    /**
     * Signaled when processing of a portion
     * of an incoming IPv6 packet should be started.
     * @param state A pointer to the processor
     *   state. For the duration of processing,
     *   the state is taken over by the implementer
     *   of the handler.
     */
    event void startProcessingIPv6PacketPortion(
            whip6_ipv6_in_packet_processing_state_t * state
    );

    /**
     * Invoked to notify that processing of a
     * portion of an incoming IPv6 packet has finished.
     */
    command void finishProcessingIPv6PacketPortion();
}

