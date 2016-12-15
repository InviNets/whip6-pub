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
 * A dedicated sender of ICMPv6 messages.
 *
 * @author Konrad Iwanicki
 */
generic configuration ICMPv6DedicatedSenderPub()
{
    provides
    {
        interface ICMPv6MessageSender[icmpv6_message_type_t msgType] @atmostonce();
    }
}
implementation
{
    enum
    {
        CLIENT_ID = unique("ICMPv6StackBasePrv::SendingClient"),
    };

    components ICMPv6StackBasePrv as BasePrv;
    components new GenericICMPv6OutgoingMessageForwarderClientAdapterPub(
            CLIENT_ID
    ) as AdapterPrv;
    
    ICMPv6MessageSender = AdapterPrv;
    AdapterPrv.SubICMPv6MessageSender -> BasePrv;
}

