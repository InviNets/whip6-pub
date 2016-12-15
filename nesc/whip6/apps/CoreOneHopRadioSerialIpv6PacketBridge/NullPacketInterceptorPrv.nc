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

#include "AddressingForCoreOneHopRadioSerialIpv6PacketBridge.h"
#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>
#include <ieee154/ucIeee154AddressManipulation.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6BasicHeaderManipulation.h>




/**
 * An IPv6 packet interceptor module of the application
 * that forms an IPv6 bridge between a one-hop radio
 * network and a serial interface.
 *
 * This particular interceptor simply drops all packets.
 *
 * @author Konrad Iwanicki
 */
module NullPacketInterceptorPrv
{
    provides
    {
        interface CoreOneHopRadioSerialIpv6PacketBridgePacketInterceptor as SerialToRadioPacketInterceptor;
        interface CoreOneHopRadioSerialIpv6PacketBridgePacketInterceptor as RadioToSerialPacketInterceptor;
        interface CoreOneHopRadioSerialIpv6PacketBridgeIeee154AddressProvider as SerialToRadioIeee154AddressProvider;
    }
    uses
    {
        interface Ieee154LocalAddressProvider;
    }
}
implementation
{
    whip6_ipv6_packet_t *   m_radioToSerialPkt = NULL;
    whip6_ipv6_packet_t *   m_serialToRadioPkt = NULL;

    task void radioToSerialInterceptTask();
    task void serialToRadioInterceptTask();



    command void RadioToSerialPacketInterceptor.startInterceptingPacket(
            whip6_ipv6_packet_t * pkt
    )
    {
        m_radioToSerialPkt = pkt;
        post radioToSerialInterceptTask();
    }



    task void radioToSerialInterceptTask()
    {
        whip6_ipv6_packet_t * pkt;

        pkt = m_radioToSerialPkt;
        m_radioToSerialPkt = NULL;
        signal RadioToSerialPacketInterceptor.finishInterceptingPacket(pkt, TRUE);
    }



    command void SerialToRadioPacketInterceptor.startInterceptingPacket(
            whip6_ipv6_packet_t * pkt
    )
    {
        m_serialToRadioPkt = pkt;
        post serialToRadioInterceptTask();
    }



    task void serialToRadioInterceptTask()
    {
        whip6_ipv6_packet_t * pkt;

        pkt = m_serialToRadioPkt;
        m_serialToRadioPkt = NULL;
        signal SerialToRadioPacketInterceptor.finishInterceptingPacket(pkt, TRUE);
    }



    command error_t SerialToRadioIeee154AddressProvider.computeIeee154AddressForOutgoingPacket(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t * outgoingIeee154Addr
    )
    {
        return FAIL;
    }
}

