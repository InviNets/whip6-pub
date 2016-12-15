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

#include <6lowpan/uc6LoWPANIpv6AddressManipulation.h>
#include <ipv6/ucIpv6AddressTypes.h>



/**
 * The implementation of a setter for a fixed IPv6
 * address prefix for nodes based on Whisper Core.
 *
 * @param pref_0  The first (most significant) two bytes of the prefix.
 * @param pref_1  The second two byte of the prefix.
 * @param pref_2  The third two byte of the prefix.
 * @param pref_3  The fourth two byte of the prefix.
 *
 * @author Konrad Iwanicki
 */
generic module CoreLoWPANFixedIPv6PrefixSetterPrv(
        uint16_t pref_0,
        uint16_t pref_1,
        uint16_t pref_2,
        uint16_t pref_3
)
{
    provides
    {
        interface SynchronousStarter @exactlyonce();
    }
    uses
    {
        interface Ieee154LocalAddressProvider @exactlyonce();
        interface IPv6InterfaceStateUpdater @exactlyonce();
    }
}
implementation
{
    command error_t SynchronousStarter.start()
    {
        whip6_ipv6_addr_t *   ipv6AddrPtr;
        uint8_t_xdata *       addrPtr;
        
        ipv6AddrPtr = call IPv6InterfaceStateUpdater.addNewUnicastAddressAsLast();
        if (ipv6AddrPtr == NULL)
        {
            return ENOMEM;
        }
        addrPtr = &(ipv6AddrPtr->data8[0]);
        *addrPtr = (uint8_t)((pref_0) >> 8);
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_0));
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_1) >> 8);
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_1));
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_2) >> 8);
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_2));
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_3) >> 8);
        ++addrPtr;
        *addrPtr = (uint8_t)((pref_3));
        ++addrPtr;
        whip6_ipv6AddrFillSuffixWithIeee154AddrAny(
                ipv6AddrPtr,
                call Ieee154LocalAddressProvider.getAddrPtr(),
                call Ieee154LocalAddressProvider.getPanIdPtr()
        );
        call IPv6InterfaceStateUpdater.compactAssociatedAddresses();
        return SUCCESS;
    }
}

