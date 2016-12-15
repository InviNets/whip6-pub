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

