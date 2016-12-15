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
 * A module for failing the processing of incoming
 * IPv6 packets on extension headers that are
 * explicitly unsupported.
 *
 * @author Konrad Iwanicki 
 */
module IPv6ExtensionHeaderFailerForIncomingPacketProcessorPrv
{
    uses
    {
        interface IPv6PacketReceiver[ipv6_next_header_field_t nxtHdrId];
    }
}
implementation
{
    event inline error_t IPv6PacketReceiver.startReceivingIPv6Packet[ipv6_next_header_field_t nxtHdrId](
            whip6_ipv6_in_packet_processing_state_t * inPacket
    )
    {
        return ENOSYS;
    }
}

