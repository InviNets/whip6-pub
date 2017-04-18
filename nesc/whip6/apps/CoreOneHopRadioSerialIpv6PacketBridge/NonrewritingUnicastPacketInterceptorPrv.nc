/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
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
 * This particular interceptor assumes that each node
 * can be reached on address consisting of a given global
 * prefix and the nodes's IEEE 802.15.4 MAC address.
 * No multicast communication is supported.
 * Packets flowing the other way, in turn, must not
 * have link-local addresses.
 *
 * @author Konrad Iwanicki
 */
module NonrewritingUnicastPacketInterceptorPrv
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
    uint8_t_code const   m_ipv6AddrNodeUnicastPrefix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_SNODE_PRF1 >> 8), (uint8_t)APP_SNODE_PRF1,
            (uint8_t)(APP_SNODE_PRF2 >> 8), (uint8_t)APP_SNODE_PRF2,
            (uint8_t)(APP_SNODE_PRF3 >> 8), (uint8_t)APP_SNODE_PRF3,
            (uint8_t)(APP_SNODE_PRF4 >> 8), (uint8_t)APP_SNODE_PRF4};

    whip6_ipv6_packet_t *   m_radioToSerialPkt = NULL;
    whip6_ipv6_packet_t *   m_serialToRadioPkt = NULL;
    whip6_ieee154_addr_t    m_tmpIeee154Addr;

    bool addressMatchesNodeUnicastPrefix(whip6_ipv6_addr_t const * addr);

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
        whip6_ipv6_addr_t *    addr;
        whip6_ipv6_packet_t *  pkt;
        bool                   drop;

        pkt = m_radioToSerialPkt;
        m_radioToSerialPkt = NULL;
        drop = TRUE;

        // Check the source address.
        addr = whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(&pkt->header);
        if (whip6_ipv6AddrIsMulticast(addr) ||
                whip6_ipv6AddrGetScope(addr) <= IPV6_ADDRESS_SCOPE_LINK_LOCAL)
        {
            goto FINISH;
        }

        // Check the destination address.
        addr = whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(&pkt->header);
        if (whip6_ipv6AddrGetScope(addr) <= IPV6_ADDRESS_SCOPE_LINK_LOCAL)
        {
            goto FINISH;
        }

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
        whip6_ipv6_addr_t *    addr;
        whip6_ipv6_packet_t *  pkt;
        bool                   drop;

        pkt = m_serialToRadioPkt;
        m_serialToRadioPkt = NULL;
        drop = TRUE;

        // Check the destination address.
        addr = whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(&pkt->header);
        if (whip6_ipv6AddrIsMulticast(addr))
        {
            goto FINISH;
        }
        if (! addressMatchesNodeUnicastPrefix(addr))
        {
            goto FINISH;
        }

        drop = FALSE;

    FINISH:
        signal SerialToRadioPacketInterceptor.finishInterceptingPacket(pkt, drop);
    }



    command error_t SerialToRadioIeee154AddressProvider.computeIeee154AddressForOutgoingPacket(
            whip6_ipv6_packet_t * pkt,
            whip6_ieee154_addr_t * outgoingIeee154Addr
    )
    {
        whip6_ipv6_addr_t const * ipv6Addr;

        ipv6Addr = whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&pkt->header);
        whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
                ipv6Addr,
                outgoingIeee154Addr,
                call Ieee154LocalAddressProvider.getPanIdPtr()
        );

        return SUCCESS;
    }



    bool addressHalvesMatch(
            uint8_t_xdata const * ptr1,
            uint8_t_code const * ptr2
    )
    {
        uint8_t   i;
        for (i = IPV6_ADDRESS_LENGTH_IN_BYTES >> 1; i > 0; --i)
        {
            if (*ptr1 != *ptr2)
            {
                return FALSE;
            }
            ++ptr1;
            ++ptr2;
        }
        return TRUE;
    }



    inline bool addressMatchesNodeUnicastPrefix(whip6_ipv6_addr_t const * addr)
    {
        return addressHalvesMatch(&(addr->data8[0]), &(m_ipv6AddrNodeUnicastPrefix[0]));
    }
}
