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
 * address provider that utilizes extended
 * IEEE 802.15.4 addresses based on EUI-64
 * as well as short addresses fixed at compile time.
 *
 * @param pan_id The PAN identifier assigned to
 *   the node.
 * @param short_id The short identifier assigned to
 *   the node.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 */

uint16_t_code NODE_SHORT_ADDR_2B = IEEE154_SHORT_NULL_ADDR;

generic module FixedShortIdAndEui64LocalIeee154AddressProviderPrv(
    uint16_t pan_id,
    uint16_t short_id
)
{
    provides
    {
        interface Init;
        interface Ieee154LocalAddressProvider;
    }
    uses
    {
        interface LocalIeeeEui64Provider;
    }
}
implementation
{
    whip6_ieee154_pan_id_t     m_panId;
    whip6_ieee154_addr_t       m_shrtAddr;
    whip6_ieee154_addr_t       m_extAddr;

    command error_t Init.init()
    {
        ieee_eui64_t   eui64;
        uint8_t        i;

        m_panId.data[0] = (uint8_t)pan_id;
        m_panId.data[1] = (uint8_t)(pan_id >> 8);

        m_shrtAddr.mode = IEEE154_ADDR_MODE_SHORT;
        if (NODE_SHORT_ADDR_2B != IEEE154_SHORT_NULL_ADDR) {
            m_shrtAddr.vars.shrt.data[0] = (uint8_t)NODE_SHORT_ADDR_2B;
            m_shrtAddr.vars.shrt.data[1] = (uint8_t)(NODE_SHORT_ADDR_2B >> 8);
        }
        else if (short_id != IEEE154_SHORT_NULL_ADDR) {
            m_shrtAddr.vars.shrt.data[0] = (uint8_t)short_id;
            m_shrtAddr.vars.shrt.data[1] = (uint8_t)(short_id >> 8);
        }
        else {
            m_shrtAddr.mode = IEEE154_ADDR_MODE_NONE;
        }


        call LocalIeeeEui64Provider.read(&eui64);
        m_extAddr.mode = IEEE154_ADDR_MODE_EXT;
        for (i = 0; i < IEEE154_EXT_ADDR_BYTE_LENGTH; ++i)
        {
            m_extAddr.vars.ext.data[i] = eui64.data[(IEEE154_EXT_ADDR_BYTE_LENGTH - 1) - i];
        }
        return SUCCESS;
    }

    command inline void Ieee154LocalAddressProvider.getExtAddr(
            whip6_ieee154_ext_addr_t * addr
    )
    {
        whip6_ieee154AddrExtCpy(&m_extAddr.vars.ext, addr);
    }

    command inline whip6_ieee154_ext_addr_t const * Ieee154LocalAddressProvider.getExtAddrPtr()
    {
        return &m_extAddr.vars.ext;
    }

    command inline bool Ieee154LocalAddressProvider.hasShortAddr()
    {
        return m_shrtAddr.mode != IEEE154_ADDR_MODE_NONE;
    }

    command inline void Ieee154LocalAddressProvider.getShortAddr(
            whip6_ieee154_short_addr_t * addr
    )
    {
        whip6_ieee154AddrShortCpy(&m_shrtAddr.vars.shrt, addr);
    }

    command inline whip6_ieee154_short_addr_t const * Ieee154LocalAddressProvider.getShortAddrPtr()
    {
        return &m_shrtAddr.vars.shrt;
    }

    command inline void Ieee154LocalAddressProvider.getAddr(
            whip6_ieee154_addr_t * addr
    )
    {
        if (m_shrtAddr.mode != IEEE154_ADDR_MODE_NONE)
            whip6_ieee154AddrAnyCpy(&m_shrtAddr, addr);
        else
            whip6_ieee154AddrAnyCpy(&m_extAddr, addr);
    }

    command inline whip6_ieee154_addr_t const * Ieee154LocalAddressProvider.getAddrPtr()
    {
        if (m_shrtAddr.mode != IEEE154_ADDR_MODE_NONE)
            return &m_shrtAddr;
        else
            return &m_extAddr;
    }

    command inline void Ieee154LocalAddressProvider.getPanId(
            whip6_ieee154_pan_id_t * panId
    )
    {
        whip6_ieee154PanIdCpy(&m_panId, panId);
    }

    command inline whip6_ieee154_pan_id_t const * Ieee154LocalAddressProvider.getPanIdPtr()
    {
        return &m_panId;
    }
}

