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

#include <ieee154/ucIeee154Ipv6InterfaceStateManipulation.h>
#include <ieee154/ucIeee154Ipv6InterfaceStateTypes.h>
#include <ipv6/ucIpv6AddressManipulation.h>
#include <ipv6/ucIpv6GenericInterfaceStateManipulation.h>



/**
 * A manager of the IPv6 state for a 6LoWPAN-compatible
 * network interface (radio).
 *
 * @param max_num_unicast_addrs The maximal number of
 *   custom unicast addresses. Should be at least 1.
 * @param max_num_multicast_addrs The maximal number of
 *   custom multicast addresses. Should be at least 1.
 *
 * @author Konrad Iwanicki
 */
generic module LoWPANIPv6InterfaceStateManagerPrv(
        uint8_t max_num_unicast_addrs,
        uint8_t max_num_multicast_addrs
)
{
    provides
    {
        interface Init @exactlyonce();
        interface SynchronousStarter @exactlyonce();
        interface IPv6InterfaceStateProvider as GenericIPv6InterfaceStateProvider;
        interface LoWPANIPv6InterfaceStateProvider;
        interface IPv6InterfaceStateUpdater as GenericIPv6InterfaceStateUpdater;
        interface LoWPANIPv6InterfaceStateUpdater;
    }
    uses
    {
        interface Ieee154LocalAddressProvider;
    }
}
implementation
{
    enum
    {
        MAX_NUM_UNICAST_ADDRS = max_num_unicast_addrs,
        MAX_NUM_MULTICAST_ADDRS = max_num_multicast_addrs,
    };


    whip6_ipv6_net_iface_ieee154_state_t   m_ifaceState;
    whip6_ipv6_addr_t                      m_unicastAddrArr[MAX_NUM_UNICAST_ADDRS];
    whip6_ipv6_addr_t                      m_multicastAddrArr[MAX_NUM_MULTICAST_ADDRS];



    command error_t Init.init()
    {
        whip6_ipv6InterfaceSetType(
                &m_ifaceState.genericState,
                WHIP6_IPV6_NET_IFACE_GENERIC_STATE_TYPE_IEEE154
        );
        whip6_ipv6InterfaceSetUnicastAddrArray(
                &m_ifaceState.genericState,
                &(m_unicastAddrArr[0]),
                0
        );
        whip6_ipv6InterfaceSetMulticastAddrArray(
                &m_ifaceState.genericState,
                &(m_multicastAddrArr[0]),
                0
        );
        return SUCCESS;
    }



    command error_t SynchronousStarter.start()
    {
        if (whip6_ipv6InterfaceHasOnFlag(&m_ifaceState.genericState))
        {
            return EALREADY;
        }
        call Ieee154LocalAddressProvider.getExtAddr(&m_ifaceState.ieee154ExtAddr);
        if (call Ieee154LocalAddressProvider.hasShortAddr())
        {
            call Ieee154LocalAddressProvider.getShortAddr(&m_ifaceState.ieee154ShrtAddr);
            whip6_ipv6InterfaceSetShortIeee154AddrFlag(&m_ifaceState.genericState);
        }
        else
        {
            whip6_ipv6InterfaceClearShortIeee154AddrFlag(&m_ifaceState.genericState);
        }
        call Ieee154LocalAddressProvider.getPanId(&m_ifaceState.ieee154PanId);
        whip6_ipv6InterfaceSetOnFlag(&m_ifaceState.genericState);
        return SUCCESS;
    }



    command inline whip6_ipv6_net_iface_generic_state_t * GenericIPv6InterfaceStateProvider.getInterfaceStatePtr()
    {
        return &m_ifaceState.genericState;
    }



    command inline whip6_ipv6_net_iface_ieee154_state_t * LoWPANIPv6InterfaceStateProvider.getLoWPANInterfaceStatePtr()
    {
        return &m_ifaceState;
    }



    command void GenericIPv6InterfaceStateUpdater.clearAssociatedAddresses()
    {
        m_ifaceState.genericState.unicastAddrArrLen = 0;
        m_ifaceState.genericState.multicastAddrArrLen = 0;
    }



    command inline whip6_ipv6_addr_t * GenericIPv6InterfaceStateUpdater.addNewUnicastAddressAsLast()
    {
        return whip6_ipv6InterfaceAssociateUnicastAddr(
                &m_ifaceState.genericState,
                MAX_NUM_UNICAST_ADDRS
        );
    }



    command void GenericIPv6InterfaceStateUpdater.compactAssociatedAddresses()
    {
        whip6_ipv6InterfaceVerifyUnicastAddrs(
                &m_ifaceState.genericState,
                MAX_NUM_UNICAST_ADDRS
        );
        whip6_ipv6InterfaceVerifyMulticastAddrs(
                &m_ifaceState.genericState,
                MAX_NUM_MULTICAST_ADDRS
        );
    }



    command inline void LoWPANIPv6InterfaceStateUpdater.updateIPv6AddressesAfterShortIeee154AddressUpdate()
    {
        // TODO iwanicki 2013-10-29:
        // If we ever have short addresses, this
        // command should be implemented.
        m_ifaceState.genericState.flags &= ~WHIP6_IPV6_NET_IFACE_IEEE154_STATE_FLAG_HAS_SHORT_ADDR;
    }
}

