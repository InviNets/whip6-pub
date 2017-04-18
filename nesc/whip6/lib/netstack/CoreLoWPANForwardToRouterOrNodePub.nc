/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


generic configuration CoreLoWPANForwardToRouterOrNodePub(uint16_t routerAddrId) {}
implementation
{
#ifndef WHIP6_IPV6_6LOWPAN_DISABLE
    components CoreIPv6StackPrv as IPv6StackPrv;

    components new ThisIeee154ShortAddrAlwaysListensPub(routerAddrId);

    components new CoreLoWPANForwardToRouterOrNodePrv(routerAddrId) as ImplPrv;
    IPv6StackPrv.LoWPANSimpleRoutingStrategy -> ImplPrv;

    components NetStackConfigPub;
    ImplPrv.Ipv6RoutingSimpleStrategyRetryRouterAfterMillis ->
        NetStackConfigPub.Ipv6RoutingSimpleStrategyRetryRouterAfterMillis;

    components new PlatformTimerMilliPub() as T1;
    ImplPrv.RouterRetryTimer -> T1;

    components BoardStartupPub as StartupPrv;
    StartupPrv.InitSequence[1] -> ImplPrv.Init;
#endif // WHIP6_IPV6_6LOWPAN_DISABLE
}
