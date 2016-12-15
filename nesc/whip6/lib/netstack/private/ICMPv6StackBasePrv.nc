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

#include "NetStackCompileTimeConfig.h"



/**
 * The base of the ICMPv6 for platforms
 * based on Whisper Core.
 *
 * @author Konrad Iwanicki
 */
configuration ICMPv6StackBasePrv
{
    provides
    {
        interface ICMPv6MessageSender[uint8_t clientId, icmpv6_message_type_t msgType];
        interface ICMPv6MessageReceiver[icmpv6_message_type_t msgType] @atmostonce();
    }
    uses
    {
        interface IPv6PacketSourceAddressSelector @exactlyonce();
        interface IPv6PacketSender @exactlyonce();
        interface IPv6PacketReceiver @exactlyonce();
    }
}
implementation
{
    enum
    {
        NUM_SENDING_CLIENTS = uniqueCount("ICMPv6StackBasePrv::SendingClient"),
    };
    
    enum
    {
        MAX_CONCURRENT_PACKETS = WHIP6_ICMPV6_MAX_CONCURRENT_PACKETS,
    };
    
    components BoardStartupPub as StartupPrv;

#ifndef WHIP6_IPV6_ICMPV6_DISABLE
    components new GenericICMPv6StackBasePub(
            NUM_SENDING_CLIENTS,
            MAX_CONCURRENT_PACKETS
    ) as ImplPrv;
    components new PlatformIPv6ChecksumComputerPub() as InChecksumComputerPrv;
    components new PlatformIPv6ChecksumComputerPub() as OutChecksumComputerPrv;

    ImplPrv.OutgoingChecksumComputer -> OutChecksumComputerPrv;
    ImplPrv.IncomingChecksumComputer -> InChecksumComputerPrv;
#else
    components new NullICMPv6StackBasePub() as ImplPrv;
#endif // WHIP6_IPV6_ICMPV6_DISABLE

    StartupPrv.InitSequence[1] -> ImplPrv;

    ImplPrv.IPv6PacketSourceAddressSelector = IPv6PacketSourceAddressSelector;
    ImplPrv.IPv6PacketSender = IPv6PacketSender;
    ImplPrv.IPv6PacketReceiver = IPv6PacketReceiver;

    ICMPv6MessageSender = ImplPrv.ICMPv6MessageSender;
    ICMPv6MessageReceiver = ImplPrv.ICMPv6MessageReceiver;
}
