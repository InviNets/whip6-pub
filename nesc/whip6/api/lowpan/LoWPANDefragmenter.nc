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

#include <6lowpan/uc6LoWPANHeaderTypes.h>
#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * A defragmenter of 6LoWPAN frames.
 *
 * @author Konrad Iwanicki
 */
interface LoWPANDefragmenter
{

    /**
     * An event signaled when an IPv6 packet has been
     * defragmented successfully.
     * @param packet The defragmented packet. The
     *   handler of the event takes full responsibility
     *   for the packet. In particular, it has to free it.
     * @param lastLinkAddr A pointer to the link-layer
     *   address from the last frame completing the packet
     *   has arrived. The pointer is valid only until
     *   the handler of the event returns.
     */
    event void defragmentingIpv6PacketFinished(
            whip6_ipv6_packet_t * packet,
            whip6_ieee154_addr_t const * lastLinkAddr
    );
}

