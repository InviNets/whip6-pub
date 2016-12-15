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

#include <ieee154/ucIeee154AddressManipulation.h>
#include "Ieee154.h"


/**
 * An implementation of a local IEEE 802.15.4
 * address provider that can be configured to
 * provide arbitrary addres - short or long.
 *
 * @author Przemysław Horban
 */
generic module RuntimeConfigurableLocalIeee154AddressPub()
{
    provides interface Ieee154ConfigureAddress;
    provides interface Ieee154LocalAddressProvider;
}
implementation
{
    whip6_ieee154_pan_id_t     m_panId;
    whip6_ieee154_ext_addr_t const *m_extAddrPtr;
    whip6_ieee154_addr_t m_addr;

    command void Ieee154ConfigureAddress.setAddress(
                    whip6_ieee154_pan_id_t const *panIdPtr,
                    whip6_ieee154_ext_addr_t const *extAddrPtr,
                    whip6_ieee154_short_addr_t const *shrtAddrPtr) {
        // PAN ID
        if (panIdPtr == NULL) {
            m_panId.data[0] = (uint8_t)WHIP6_IEEE154_PAN_ID;
            m_panId.data[1] = (uint8_t)(WHIP6_IEEE154_PAN_ID >> 8);
        } else {
            whip6_ieee154PanIdCpy(panIdPtr, &m_panId);
        }

        // EXT Addr.
        if (extAddrPtr == NULL)
            panic();

        m_extAddrPtr = extAddrPtr;

        // SHORT if available
        if (shrtAddrPtr != NULL) {
            m_addr.mode = IEEE154_ADDR_MODE_SHORT;
            whip6_ieee154AddrShortCpy(shrtAddrPtr, &m_addr.vars.shrt);
        } else {
            m_addr.mode = IEEE154_ADDR_MODE_EXT;
            whip6_ieee154AddrExtCpy(extAddrPtr, &m_addr.vars.ext);
        }
    }

    command inline void Ieee154LocalAddressProvider.getExtAddr(
            whip6_ieee154_ext_addr_t * addr
    )
    {
        whip6_ieee154AddrExtCpy(m_extAddrPtr, addr);
    }

    command inline whip6_ieee154_ext_addr_t const * Ieee154LocalAddressProvider.getExtAddrPtr()
    {
        return m_extAddrPtr;
    }

    command inline bool Ieee154LocalAddressProvider.hasShortAddr()
    {
        return m_addr.mode == IEEE154_ADDR_MODE_SHORT;
    }

    command inline void Ieee154LocalAddressProvider.getShortAddr(
            whip6_ieee154_short_addr_t * addr
    )
    {
        whip6_ieee154AddrShortCpy(&m_addr.vars.shrt, addr);
    }

    command inline whip6_ieee154_short_addr_t const * Ieee154LocalAddressProvider.getShortAddrPtr()
    {
        return &m_addr.vars.shrt;
    }

    command inline void Ieee154LocalAddressProvider.getAddr(
            whip6_ieee154_addr_t * addr
    )
    {
        whip6_ieee154AddrAnyCpy(&m_addr, addr);
    }

    command inline whip6_ieee154_addr_t const * Ieee154LocalAddressProvider.getAddrPtr()
    {
        return &m_addr;
    }

    command inline void Ieee154LocalAddressProvider.getPanId(
            whip6_ieee154_pan_id_t * panIdPtr
    )
    {
        whip6_ieee154PanIdCpy(&m_panId, panIdPtr);
    }

    command inline whip6_ieee154_pan_id_t const * Ieee154LocalAddressProvider.getPanIdPtr()
    {
        return &m_panId;
    }
}

