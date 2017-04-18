/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
 * This particular interceptor assumes that there are
 * only two nodes and all packets should be forwarded
 * to the other one.
 *
 * @author Szymon Acedanski
 */
module PointToPointPacketInterceptorPrv
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
    uint8_t_code const   m_ieee154AddrDefaultGateway[IEEE154_EXT_ADDR_BYTE_LENGTH] = {
            (uint8_t)(APP_PEER_LLADDR1 >> 8), (uint8_t)APP_PEER_LLADDR1,
            (uint8_t)(APP_PEER_LLADDR2 >> 8), (uint8_t)APP_PEER_LLADDR2,
            (uint8_t)(APP_PEER_LLADDR3 >> 8), (uint8_t)APP_PEER_LLADDR3,
            (uint8_t)(APP_PEER_LLADDR4 >> 8), (uint8_t)APP_PEER_LLADDR4};

    whip6_ipv6_packet_t *   m_radioToSerialPkt = NULL;
    whip6_ipv6_packet_t *   m_serialToRadioPkt = NULL;
    whip6_ieee154_addr_t    m_tmpIeee154Addr;


    void rewriteIeee154ExtAddress(whip6_ieee154_addr_t * dst, uint8_t_code const * ptr2);

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
        whip6_ipv6_packet_t *  pkt;
        bool                   drop;
        uint8_t                hop_limit;

        pkt = m_radioToSerialPkt;
        m_radioToSerialPkt = NULL;
        drop = TRUE;

        hop_limit = whip6_ipv6BasicHeaderGetHopLimit(&pkt->header);
        if (hop_limit == 1)
        {
            goto FINISH;
        }
        whip6_ipv6BasicHeaderSetHopLimit(&pkt->header, hop_limit - 1);

        drop = FALSE;

    FINISH:
        signal RadioToSerialPacketInterceptor.finishInterceptingPacket(pkt, drop);
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
        whip6_ipv6_packet_t *  pkt;
        bool                   drop;
        uint8_t                hop_limit;

        pkt = m_serialToRadioPkt;
        m_serialToRadioPkt = NULL;
        drop = TRUE;

        hop_limit = whip6_ipv6BasicHeaderGetHopLimit(&pkt->header);
        if (hop_limit == 1)
        {
            goto FINISH;
        }
        whip6_ipv6BasicHeaderSetHopLimit(&pkt->header, hop_limit - 1);

        drop = FALSE;

    FINISH:
        signal SerialToRadioPacketInterceptor.finishInterceptingPacket(pkt, drop);
    }



    command error_t SerialToRadioIeee154AddressProvider.computeIeee154AddressForOutgoingPacket(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t * outgoingIeee154Addr
    )
    {
        rewriteIeee154ExtAddress(outgoingIeee154Addr, m_ieee154AddrDefaultGateway);
        return SUCCESS;
    }



    void rewriteIeee154ExtAddress(whip6_ieee154_addr_t * dst, uint8_t_code const * ptr2)
    {
        uint8_t   i;
        uint8_t_xdata * ptr1 = dst->vars.ext.data;
        ptr2 += IEEE154_EXT_ADDR_BYTE_LENGTH;
        for (i = IEEE154_EXT_ADDR_BYTE_LENGTH; i > 0; --i)
        {
            --ptr2;
            *ptr1 = (*ptr2);
            ++ptr1;
        }
        dst->mode = IEEE154_ADDR_MODE_EXT;
    }
}
