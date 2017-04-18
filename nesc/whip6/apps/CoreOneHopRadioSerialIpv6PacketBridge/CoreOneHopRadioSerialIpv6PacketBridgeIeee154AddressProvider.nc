/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A provider of link-layer addresses for outgoing radio
 * packets.
 * 
 * @author Szymon Acedanski
 */
interface CoreOneHopRadioSerialIpv6PacketBridgeIeee154AddressProvider
{
    /**
     * Computes the link-layer address to use as
     * the destination for sending the given
     * packet over the radio.
     * @param pkt The packet to send.
     * @param outgoingIeee154Addr The pointer,
     *   where the address should be stored.
     */
    command error_t computeIeee154AddressForOutgoingPacket(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t * outgoingIeee154Addr
    );

}
