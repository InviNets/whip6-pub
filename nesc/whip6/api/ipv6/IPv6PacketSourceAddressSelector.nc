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
 * A selector of source addresses for IPv6 packets
 * originating at the present node.
 *
 * @see IPv6PacketSender
 * @see IPv6PacketReceiver
 *
 * @author Konrad Iwanicki
 */
interface IPv6PacketSourceAddressSelector
{
    /**
     * Initiates selecting a source address for IPv6 packet.
     * @param outPacket A pointer to the processing state
     *   for the packet.
     * @return SUCCESS if the address selection procedure was
     *   initiated successfully, in which case the implementer
     *   takes over the ownership of the state and
     *   guarantees to signal the end of selection;
     *   or an error code otherwise, in which case
     *   the ownership of the state stays with the
     *   caller and no end of selection will be signaled.
     */
    command error_t startSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket
    );

    /**
     * Signaled to notify that selecting a source address
     * for IPv6 packet has finished. IMPORTANT: It is assumed
     * that after the source address has been selected,
     * no modifications to either the source or the
     * destination address will be done.
     * @param outPacket A pointer to the processing state
     *   of the packet whose source address selection has
     *   finished. The ownership of the state is transferred
     *   to the implementer.
     * @param status SUCCESS denotes that the address has
     *   been selected; otherwise the value inidcates an error
     *   code.
     */
    event void finishSelectingSourceAddressForIPv6Packet(
            whip6_ipv6_out_packet_processing_state_t * outPacket,
            error_t status
    );
}
