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
 * A provider for an extended IEEE 802.15.4 address representing
 * a default route for the 6LoWPAN IPv6 stack.
 *
 * @param msb_0  The first (most significant) byte of the address.
 * @param msb_1  The second byte of the address.
 * @param msb_2  The third byte of the address.
 * @param msb_3  The fourth byte of the address.
 * @param msb_4  The fifth byte of the address.
 * @param msb_5  The sixth byte of the address.
 * @param msb_6  The seventh byte of the address.
 * @param msb_7  The eighth (least significant) byte of the address.
 *
 * @author Konrad Iwanicki
 */
generic configuration CoreLoWPANDefaultRouteViaConstIeee154ExtAddrProviderPub(
        uint8_t msb_0,
        uint8_t msb_1,
        uint8_t msb_2,
        uint8_t msb_3,
        uint8_t msb_4,
        uint8_t msb_5,
        uint8_t msb_6,
        uint8_t msb_7
)
{
}
implementation
{
    components CoreIPv6StackPrv as IPv6StackPrv;

#ifndef WHIP6_IPV6_6LOWPAN_DISABLE

    components new GenericLoWPANDefaultRouteViaConstIeee154ExtAddrProviderPub(
            msb_0,
            msb_1,
            msb_2,
            msb_3,
            msb_4,
            msb_5,
            msb_6,
            msb_7
    ) as ImplPrv;

    IPv6StackPrv.LoWPANSimpleRoutingStrategy -> ImplPrv;

#endif // WHIP6_IPV6_6LOWPAN_DISABLE
}
