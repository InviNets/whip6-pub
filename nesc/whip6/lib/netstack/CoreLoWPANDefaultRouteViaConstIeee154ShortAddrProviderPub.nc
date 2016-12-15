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




/**
 * A provider for a short IEEE 802.15.4 address representing
 * a default route for the 6LoWPAN IPv6 stack.
 *
 * @param shortId The short identifier assigned to the node.
 *
 * @author Konrad Iwanicki
 */
generic configuration CoreLoWPANDefaultRouteViaConstIeee154ShortAddrProviderPub(
        uint16_t shortId
)
{
}
implementation
{
    components CoreIPv6StackPrv as IPv6StackPrv;

#ifndef WHIP6_IPV6_6LOWPAN_DISABLE

    components new GenericLoWPANDefaultRouteViaConstIeee154ShortAddrProviderPub(
            shortId
    ) as ImplPrv;

    IPv6StackPrv.LoWPANSimpleRoutingStrategy -> ImplPrv;

#endif // WHIP6_IPV6_6LOWPAN_DISABLE
}

