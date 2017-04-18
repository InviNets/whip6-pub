/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ipv6/ucIpv6PacketTypes.h>


/**
 * A cloner for IPv6 packets.
 *
 * @author Konrad Iwanicki
 */
interface IPv6PacketCloner
{
    /**
     * Stars cloning a packet.
     * @param orgPacket The packet to be cloned.
     * @return SUCCESS if the cloning has been started
     *   successfully, in which case the
     *   <tt>finishCloningIPv6Packet</tt> is guaranteed
     *   to be signaled; an error code otherwise, in which case
     *   no <tt>finishCloningIPv6Packet</tt> will be signaled.
     *   Possible error codes:
     *     ENOMEM if there is no memory to clone the packet;
     *     EBUSY if the cloner is busy cloning another packet;
     *     EINVAL if the packet is invalid.
     */
    command error_t startCloningIPv6Packet(
            whip6_ipv6_packet_t const * orgPacket
    );

    /**
     * Signaled when cloning an IPv6 packet has
     * finished.
     * @param orgPacket A pointer to the original
     *   packet.
     * @param clonePacketOrNull A pointer to the
     *   clone of the original packet or NULL if
     *   the clone has not been created.
     */
    event void finishCloningIPv6Packet(
            whip6_ipv6_packet_t const * orgPacket,
            whip6_ipv6_packet_t * clonePacketOrNull
    );
}
