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

#include "UDPEcho.h"



/**
 * A simple UDP echo application.
 *
 * For more information, please, refer to the
 * associated README file.
 *
 * @author Konrad Iwanicki
 */
configuration UDPEchoApp
{
}
implementation
{
    components UDPEchoMainPrv as AppMainPrv;
    components new PlatformTimerMilliPub() as ClientTimerPrv;
    components new SimpleUDPSocketPub() as ClientSocketPrv;
    components new SimpleUDPSocketPub() as ServerSocketPrv;
    components LocalIeeeEui64ProviderPub as Eui64ProviderPrv;
    components BoardStartupPub;
#ifdef APP_USE_SHORT_ROUTER_ADDR
    components new CoreLoWPANDefaultRouteViaConstIeee154ShortAddrProviderPub(
            APP_GTW_SID
    );
#else
    components new CoreLoWPANDefaultRouteViaConstIeee154ExtAddrProviderPub(
            APP_GTW_EUI1,
            APP_GTW_EUI2,
            APP_GTW_EUI3,
            APP_GTW_EUI4,
            APP_GTW_EUI5,
            APP_GTW_EUI6,
            APP_GTW_EUI7,
            APP_GTW_EUI8
    );
#endif // APP_USE_SHORT_ROUTER_ADDR
    components new CoreLoWPANFixedIPv6PrefixSetterPub(
            APP_NODE_PREF1,
            APP_NODE_PREF2,
            APP_NODE_PREF3,
            APP_NODE_PREF4
    );
    components IPv6StackPub as IPv6StackPrv;

    AppMainPrv.Boot -> BoardStartupPub;
    AppMainPrv.IPv6StackStarter -> IPv6StackPrv;
    AppMainPrv.ServerSocketController -> ServerSocketPrv;
    AppMainPrv.ServerSocketReceiver -> ServerSocketPrv;
    AppMainPrv.ServerSocketSender -> ServerSocketPrv;
    AppMainPrv.ClientSocketController -> ClientSocketPrv;
    AppMainPrv.ClientSocketReceiver -> ClientSocketPrv;
    AppMainPrv.ClientSocketSender -> ClientSocketPrv;
    AppMainPrv.ClientTimer -> ClientTimerPrv;
    AppMainPrv.LocalIeeeEui64Provider -> Eui64ProviderPrv;
    // AppMainPrv.ErrorLed -> ???;
    // AppMainPrv.ClientTxLed -> ???;
    // AppMainPrv.ServerRxLed -> ???;
}

