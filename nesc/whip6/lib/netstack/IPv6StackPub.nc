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
 * The IPv6 stack.
 *
 * @author Konrad Iwanicki
 */
configuration IPv6StackPub
{
    provides
    {
        interface SynchronousStarter @atleastonce();
    }
}
implementation
{
    components InternalIPv6StackPub as ImplPrv;

    SynchronousStarter = ImplPrv;
    
    ImplPrv.HopByHopRoutingLoopIn[WHIP6_IANA_IPV6_NO_NEXT_HEADER] ->
    ImplPrv.HopByHopRoutingLoopOut[WHIP6_IANA_IPV6_NO_NEXT_HEADER];
}
