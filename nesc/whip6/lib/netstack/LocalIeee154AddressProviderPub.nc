/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "NetStackCompileTimeConfig.h"
#include "Ieee154.h"



/**
 * A default IEEE 802.15.4 address provider
 * for the platform.
 *
 * @author Konrad Iwanicki
 */
configuration LocalIeee154AddressProviderPub
{
    provides
    {
        interface Ieee154LocalAddressProvider;
    }
}
implementation
{
    enum
    {
        PAN_ID = WHIP6_IEEE154_PAN_ID,
    };

    components BoardStartupPub;
    components LocalIeeeEui64ProviderPub as Eui64ProviderPrv;
    components new FixedShortIdAndEui64LocalIeee154AddressProviderPrv(
            PAN_ID,
#ifdef WHIP6_IEEE154_ADDRESS_SHORT
            WHIP6_IEEE154_ADDRESS_SHORT
#else
            IEEE154_SHORT_NULL_ADDR
#endif
    ) as AddrProviderImplPrv;

    Ieee154LocalAddressProvider = AddrProviderImplPrv;

    AddrProviderImplPrv.LocalIeeeEui64Provider -> Eui64ProviderPrv;    

    BoardStartupPub.InitSequence[0] -> AddrProviderImplPrv;
}
