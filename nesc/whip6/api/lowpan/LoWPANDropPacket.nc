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

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6HeaderProcessorTypes.h>

/**
 * Decides if the packet should be dropped.
 *
 * @author Przemysław Horban
 */
interface LoWPANDropPacket
{
    /**
     * Decides if the packet should be dropped.
     */
    command bool shouldDropPacket(
        whip6_ipv6_packet_t *packet,
        whip6_ipv6_addr_t const *srcAddr,
        whip6_ipv6_addr_t const *dstAddr);
}

