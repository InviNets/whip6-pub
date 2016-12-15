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
 * This particular interceptor assumes that the nodes
 * can communicate only with a single IPv6 address,
 * a so-called controller address. Moreover, it assumes
 * that the nodes can participate in a single multicast
 * group with a given multicast address. Finally, each
 * node can be reached individually at an address that
 * consists of a given prefix and the node's
 * IEEE 802.15.4 MAC.
 *
 * @author Konrad Iwanicki
 */
module SingleControllerPacketInterceptorPrv
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
    uint8_t_code const   m_ipv6AddrCtrlPrefix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_CTRL_PRF1 >> 8), (uint8_t)APP_CTRL_PRF1,
            (uint8_t)(APP_CTRL_PRF2 >> 8), (uint8_t)APP_CTRL_PRF2,
            (uint8_t)(APP_CTRL_PRF3 >> 8), (uint8_t)APP_CTRL_PRF3,
            (uint8_t)(APP_CTRL_PRF4 >> 8), (uint8_t)APP_CTRL_PRF4};
    uint8_t_code const   m_ipv6AddrCtrlSuffix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_CTRL_SUF1 >> 8), (uint8_t)APP_CTRL_SUF1,
            (uint8_t)(APP_CTRL_SUF2 >> 8), (uint8_t)APP_CTRL_SUF2,
            (uint8_t)(APP_CTRL_SUF3 >> 8), (uint8_t)APP_CTRL_SUF3,
            (uint8_t)(APP_CTRL_SUF4 >> 8), (uint8_t)APP_CTRL_SUF4};
    uint8_t_code const   m_ipv6AddrNodeUnicastPrefix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_SNODE_PRF1 >> 8), (uint8_t)APP_SNODE_PRF1,
            (uint8_t)(APP_SNODE_PRF2 >> 8), (uint8_t)APP_SNODE_PRF2,
            (uint8_t)(APP_SNODE_PRF3 >> 8), (uint8_t)APP_SNODE_PRF3,
            (uint8_t)(APP_SNODE_PRF4 >> 8), (uint8_t)APP_SNODE_PRF4};
    uint8_t_code const   m_ipv6AddrNodeMulticastPrefix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_ANODE_PRF1 >> 8), (uint8_t)APP_ANODE_PRF1,
            (uint8_t)(APP_ANODE_PRF2 >> 8), (uint8_t)APP_ANODE_PRF2,
            (uint8_t)(APP_ANODE_PRF3 >> 8), (uint8_t)APP_ANODE_PRF3,
            (uint8_t)(APP_ANODE_PRF4 >> 8), (uint8_t)APP_ANODE_PRF4};
    uint8_t_code const   m_ipv6AddrNodeMulticastSuffix[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1] = {
            (uint8_t)(APP_ANODE_SUF1 >> 8), (uint8_t)APP_ANODE_SUF1,
            (uint8_t)(APP_ANODE_SUF2 >> 8), (uint8_t)APP_ANODE_SUF2,
            (uint8_t)(APP_ANODE_SUF3 >> 8), (uint8_t)APP_ANODE_SUF3,
            (uint8_t)(APP_ANODE_SUF4 >> 8), (uint8_t)APP_ANODE_SUF4};

    whip6_ipv6_packet_t *   m_radioToSerialPkt = NULL;
    whip6_ipv6_packet_t *   m_serialToRadioPkt = NULL;
    whip6_ieee154_addr_t    m_tmpIeee154Addr;


    bool addressHalvesMatch(uint8_t_xdata const * ptr1, uint8_t_code const * ptr2);
    bool addressMatchesControllerAddress(whip6_ipv6_addr_t const * addr);
    bool addressMatchesNodeUnicastPrefix(whip6_ipv6_addr_t const * addr);
    bool addressMatchesNodeMulticastAddress(whip6_ipv6_addr_t const * addr);
    void rewriteAddressHalf(uint8_t_xdata * ptr1, uint8_t_code const * ptr2);
    void rewriteAddressWithMyAddress(whip6_ipv6_addr_t * addr);
    void rewriteAddressPrefixWithLinkLocalPrefix(whip6_ipv6_addr_t * addr);
    void rewriteAddressWithAllNodesLinkLocalAddress(whip6_ipv6_addr_t * addr);
    void rewriteAddressPrefixWithNodeUnicastPrefix(whip6_ipv6_addr_t * addr);
    void rewriteAddressWithControllerAddress(whip6_ipv6_addr_t * addr);

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

        // Check and rewrite the source address.
        addr = whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(&pkt->header);
        if (whip6_ipv6AddrIsMulticast(addr) || ! whip6_ipv6AddrIsLinkLocal(addr))
        {
            goto FINISH;
        }
        rewriteAddressPrefixWithNodeUnicastPrefix(addr);

        // Check and rewrite the destination address.
        addr = whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(&pkt->header);
        if (whip6_ipv6AddrIsMulticast(addr) || ! whip6_ipv6AddrIsLinkLocal(addr))
        {
            goto FINISH;
        }
        whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
                addr,
                &m_tmpIeee154Addr,
                call Ieee154LocalAddressProvider.getPanIdPtr()
        );
        if (whip6_ieee154AddrAnyCmp(&m_tmpIeee154Addr,
                call Ieee154LocalAddressProvider.getAddrPtr()) != 0)
        {
            goto FINISH;
        }
        rewriteAddressWithControllerAddress(addr);

        // Set the hop limit.
        whip6_ipv6BasicHeaderSetHopLimit(&pkt->header, 64);

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

        // Check and rewrite the source address.
        addr = whip6_ipv6BasicHeaderGetSrcAddrPtrForWriting(&pkt->header);
        if (! addressMatchesControllerAddress(addr))
        {
            goto FINISH;
        }
        rewriteAddressWithMyAddress(addr);

        // Check and rewrite the destination address.
        addr = whip6_ipv6BasicHeaderGetDstAddrPtrForWriting(&pkt->header);
        // NOTICE iwanicki 2013-11-08:
        // We may want to later change this. For example, we
        // may dedicate a unicast address as a multicast one.
        if (whip6_ipv6AddrIsMulticast(addr))
        {
            if (! addressMatchesNodeMulticastAddress(addr))
            {
                goto FINISH;
            }
            rewriteAddressWithAllNodesLinkLocalAddress(addr);
        }
        else
        {
            if (! addressMatchesNodeUnicastPrefix(addr))
            {
                goto FINISH;
            }
            rewriteAddressPrefixWithLinkLocalPrefix(addr);
        }

        // Set the hop limit.
        whip6_ipv6BasicHeaderSetHopLimit(&pkt->header, 1);

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

        // Check the source address.
        ipv6Addr = whip6_ipv6BasicHeaderGetSrcAddrPtrForReading(&pkt->header);
        if (whip6_ipv6AddrIsMulticast(ipv6Addr) ||
                ! whip6_ipv6AddrIsLinkLocal(ipv6Addr))
        {
            goto FAILURE_ROLLBACK_0;
        }
        whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
                ipv6Addr,
                outgoingIeee154Addr,
                call Ieee154LocalAddressProvider.getPanIdPtr()
        );
        if (whip6_ieee154AddrAnyCmp(
                outgoingIeee154Addr, call Ieee154LocalAddressProvider.getAddrPtr()) != 0)
         {
             goto FAILURE_ROLLBACK_0;
         }
 
        // Check the destination address.
        ipv6Addr = whip6_ipv6BasicHeaderGetDstAddrPtrForReading(&pkt->header);
        if (whip6_ipv6AddrGetScope(ipv6Addr) != IPV6_ADDRESS_SCOPE_LINK_LOCAL)
        {
            goto FAILURE_ROLLBACK_0;
        }
        if (whip6_ipv6AddrIsMulticast(ipv6Addr))
        {
            if (! whip6_ipv6AddrIsAllNodesMulticast(ipv6Addr))
            {
                goto FAILURE_ROLLBACK_0;
            }
            whip6_ieee154AddrAnySetBroadcast(outgoingIeee154Addr);
        }
        else
        {
            if (! whip6_ipv6AddrIsLinkLocal(ipv6Addr))
            {
                goto FAILURE_ROLLBACK_0;
            }
            whip6_ipv6AddrExtractFromSuffixIeee154AddrAny(
                    ipv6Addr,
                    outgoingIeee154Addr,
                    call Ieee154LocalAddressProvider.getPanIdPtr()
            );
        }

        return SUCCESS;

    FAILURE_ROLLBACK_0:
        return FAIL;
    }



    inline bool addressMatchesControllerAddress(
            whip6_ipv6_addr_t const * addr
    )
    {
        return addressHalvesMatch(&(addr->data8[0]), &(m_ipv6AddrCtrlPrefix[0])) &&
                addressHalvesMatch(&(addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]), &(m_ipv6AddrCtrlSuffix[0]));
    }



    inline bool addressMatchesNodeUnicastPrefix(whip6_ipv6_addr_t const * addr)
    {
        return addressHalvesMatch(&(addr->data8[0]), &(m_ipv6AddrNodeUnicastPrefix[0]));
    }



    inline bool addressMatchesNodeMulticastAddress(whip6_ipv6_addr_t const * addr)
    {
        return addressHalvesMatch(&(addr->data8[0]), &(m_ipv6AddrNodeMulticastPrefix[0])) &&
                addressHalvesMatch(&(addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]), &(m_ipv6AddrNodeMulticastSuffix[0]));
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



    void rewriteAddressWithMyAddress(whip6_ipv6_addr_t * addr)
    {
        whip6_ipv6AddrSetLinkLocalPrefix(addr);
        whip6_ipv6AddrFillSuffixWithIeee154AddrAny(
                addr,
                call Ieee154LocalAddressProvider.getAddrPtr(),
                call Ieee154LocalAddressProvider.getPanIdPtr()
        );
    }



    inline void rewriteAddressPrefixWithLinkLocalPrefix(whip6_ipv6_addr_t * addr)
    {
        whip6_ipv6AddrSetLinkLocalPrefix(addr);
    }



    inline void rewriteAddressWithAllNodesLinkLocalAddress(whip6_ipv6_addr_t * addr)
    {
        whip6_ipv6AddrSetAllNodesLinkLocalAddr(addr);
    }



    inline void rewriteAddressPrefixWithNodeUnicastPrefix(whip6_ipv6_addr_t * addr)
    {
        rewriteAddressHalf(&(addr->data8[0]), &(m_ipv6AddrNodeUnicastPrefix[0]));
    }



    inline void rewriteAddressWithControllerAddress(whip6_ipv6_addr_t * addr)
    {
        rewriteAddressHalf(&(addr->data8[0]), &(m_ipv6AddrCtrlPrefix[0]));
        rewriteAddressHalf(&(addr->data8[IPV6_ADDRESS_LENGTH_IN_BYTES >> 1]), &(m_ipv6AddrCtrlSuffix[0]));
    }



    void rewriteAddressHalf(uint8_t_xdata * ptr1, uint8_t_code const * ptr2)
    {
        uint8_t   i;
        for (i = IPV6_ADDRESS_LENGTH_IN_BYTES >> 1; i > 0; --i)
        {
            *ptr1 = (*ptr2);
            ++ptr1;
            ++ptr2;
        }
    }
}

