/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * A setter for a fixed IPv6 address prefix for nodes
 * based on Whisper Core.
 *
 * @param pref_0  The first (most significant) two bytes of the prefix.
 * @param pref_1  The second two byte of the prefix.
 * @param pref_2  The third two byte of the prefix.
 * @param pref_3  The fourth two byte of the prefix.
 *
 * @author Konrad Iwanicki
 */
generic configuration CoreLoWPANFixedIPv6PrefixSetterPub(
        uint16_t pref_0,
        uint16_t pref_1,
        uint16_t pref_2,
        uint16_t pref_3
)
{
}
implementation
{

    components CoreIPv6StackPrv as IPv6StackPrv;

#ifndef WHIP6_IPV6_6LOWPAN_DISABLE

    components CoreLoWPANStackPub as LoWPANStackPrv;
    components new CoreLoWPANFixedIPv6PrefixSetterPrv(
            pref_0,
            pref_1,
            pref_2,
            pref_3
    ) as ImplPrv;

    IPv6StackPrv.LoWPANFixedIPv6PrefixConfigurer -> ImplPrv;
    ImplPrv.Ieee154LocalAddressProvider -> LoWPANStackPrv;
    ImplPrv.IPv6InterfaceStateUpdater -> IPv6StackPrv.LoWPANIPv6InterfaceStateUpdater;

#endif // WHIP6_IPV6_6LOWPAN_DISABLE
}
