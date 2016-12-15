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

#include <NetStackRunTimeConfig.h>



/**
 * The NetStack configuration provider.
 *
 * @author Konrad Iwanicki
 */
configuration NetStackConfigPub
{
    provides
    {
        interface ConfigValue<uint32_t> as LoWPANFragmentReassemblyTimeoutInMillis;
        interface ConfigValue<uint8_t> as LoWPANMaxFrameRetransmissionAttempts;
        interface ConfigValue<uint32_t> as LoWPANBroadcastTxFailureRollbackDurationInMillis;
        interface ConfigValue<uint32_t> as LoWPANUnicastTxFailureRollbackDurationInMillis;
        interface ConfigValue<uint32_t> as LoWPANBroadcastTxSuccessRollbackDurationInMillis;
        interface ConfigValue<uint32_t> as LoWPANUnicastTxSuccessRollbackDurationInMillis;

        interface ConfigValue<bool> as Ipv6RoutingFailsOnFirstErrorOtherThanNoRoute;
        interface ConfigValue<uint32_t> as Ipv6RoutingSimpleStrategyRetryRouterAfterMillis;

        interface ConfigValue<bool> as Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6Packets;
        interface ConfigValue<bool> as Icmpv6ShouldReplyToEchoRequestsToMulticastAddresses;
    }
}
implementation
{
    components new GenericSettableConfigValueProviderPub(
            uint32_t,
            WHIP6_LOWPAN_DEFAULT_FRAGMENT_REASSEMBLY_TIMEOUT_IN_MILLIS
    ) as LoWPANFragmentReassemblyTimeoutInMillisPrv;
    LoWPANFragmentReassemblyTimeoutInMillis =
        LoWPANFragmentReassemblyTimeoutInMillisPrv;

    components new GenericSettableConfigValueProviderPub(
            uint8_t,
            WHIP6_LOWPAN_DEFAULT_MAX_FRAME_RETRANSMISSION_ATTEMPTS
    ) as LoWPANMaxFrameRetransmissionAttemptsPrv;
    LoWPANMaxFrameRetransmissionAttempts =
        LoWPANMaxFrameRetransmissionAttemptsPrv;

    components new GenericSettableConfigValueProviderPub(
            uint32_t,
            WHIP6_LOWPAN_DEFAULT_BROADCAST_FRAME_TX_FAILURE_ROLLBACK_IN_MILLIS
    ) as LoWPANBroadcastTxFailureRollbackDurationInMillisPrv;
    LoWPANBroadcastTxFailureRollbackDurationInMillis =
        LoWPANBroadcastTxFailureRollbackDurationInMillisPrv;

    components new GenericSettableConfigValueProviderPub(
            uint32_t,
            WHIP6_LOWPAN_DEFAULT_UNICAST_FRAME_TX_FAILURE_ROLLBACK_IN_MILLIS
    ) as LoWPANUnicastTxFailureRollbackDurationInMillisPrv;
    LoWPANUnicastTxFailureRollbackDurationInMillis =
        LoWPANUnicastTxFailureRollbackDurationInMillisPrv;

    components new GenericSettableConfigValueProviderPub(
            uint32_t,
            WHIP6_LOWPAN_DEFAULT_BROADCAST_FRAME_TX_SUCCESS_ROLLBACK_IN_MILLIS
    ) as LoWPANBroadcastTxSuccessRollbackDurationInMillisPrv;
    LoWPANBroadcastTxSuccessRollbackDurationInMillis =
        LoWPANBroadcastTxSuccessRollbackDurationInMillisPrv;

    components new GenericSettableConfigValueProviderPub(
            uint32_t,
            WHIP6_LOWPAN_DEFAULT_UNICAST_FRAME_TX_SUCCESS_ROLLBACK_IN_MILLIS
    ) as LoWPANUnicastTxSuccessRollbackDurationInMillisPrv;
    LoWPANUnicastTxSuccessRollbackDurationInMillis =
        LoWPANUnicastTxSuccessRollbackDurationInMillisPrv;

    components new GenericConstantConfigValueProviderPub(
            bool,
            TRUE
    ) as RoutingFailsOnFirstErrorOtherThanNoRoutePrv;
    Ipv6RoutingFailsOnFirstErrorOtherThanNoRoute =
        RoutingFailsOnFirstErrorOtherThanNoRoutePrv;

    components new GenericConstantConfigValueProviderPub(
            uint32_t,
            WHIP6_IPV6_ROUTING_SIMPLE_STRATEGY_RETRY_ROUTER_AFTER_MILLIS
    ) as Ipv6RoutingSimpleStrategyRetryRouterAfterMillisPrv;
    Ipv6RoutingSimpleStrategyRetryRouterAfterMillis =
        Ipv6RoutingSimpleStrategyRetryRouterAfterMillisPrv;

    components new BitPub() as Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6PacketsBitPrv;
    components new BitToConfigValueAdapterPub() as Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6PacketsAdapterPrv;
    Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6Packets =
        Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6PacketsAdapterPrv;
    Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6PacketsAdapterPrv.SubBit ->
        Icmpv6ErrorMessagesDisabledWhenProcessingIncomingIpv6PacketsBitPrv;

    components new BitPub() as Icmpv6ShouldReplyToEchoRequestsToMulticastAddressesBitPrv;
    components new BitToConfigValueAdapterPub() as Icmpv6ShouldReplyToEchoRequestsToMulticastAddressesAdapterPrv;
    Icmpv6ShouldReplyToEchoRequestsToMulticastAddresses =
        Icmpv6ShouldReplyToEchoRequestsToMulticastAddressesAdapterPrv;
    Icmpv6ShouldReplyToEchoRequestsToMulticastAddressesAdapterPrv.SubBit ->
        Icmpv6ShouldReplyToEchoRequestsToMulticastAddressesBitPrv;
}

