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

#include <ipv6/ucIpv6PacketTypes.h>



/**
 * An interceptor of IPv6 packets for the application
 * that forms an IPv6 bridge between a one-hop radio
 * network and a serial interface.
 * 
 * @author Konrad Iwanicki
 */
interface CoreOneHopRadioSerialIpv6PacketBridgePacketInterceptor
{
    /**
     * Starts processing an intercepted packet.
     * The implementer MUST later signal the
     * <tt>finishInterceptingPacket</tt> event.
     * @param pkt The intercepted packet.
     */
    command void startInterceptingPacket(
            whip6_ipv6_packet_t * pkt
    );

    /**
     * Signaled when processing an intercepted
     * packet has finished.
     * @param pkt The intercepted packet.
     * @param drop TRUE if the packet should be
     *   dropped or FALSE otherwise.
     */
    event void finishInterceptingPacket(
            whip6_ipv6_packet_t * pkt,
            bool drop
    );

}

