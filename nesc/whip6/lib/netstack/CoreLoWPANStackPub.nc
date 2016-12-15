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
 * An entire 6LoWPAN radio stack for
 * WhisperCore-based platforms.
 *
 * @author Konrad Iwanicki
 */
configuration CoreLoWPANStackPub
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANIPv6PacketForwarder;
        interface LoWPANIPv6PacketAcceptor;
        interface LoWPANLinkTable;
        interface Ieee154LocalAddressProvider;
    }
    uses
    {
        // Disabled during RiMAC transistion
        // interface StatsIncrementer<uint8_t> as RadioNumSuccessfulRXStat;
        // interface StatsIncrementer<uint8_t> as RadioNumSuccessfulTXStat;
        // interface StatsIncrementer<uint8_t> as RadioNumLengthErrorsStat;
        // interface StatsIncrementer<uint8_t> as RadioNumCRCErrorsStat;
        // interface StatsIncrementer<uint8_t> as RadioNumTXTimeoutErrorsStat;
        // interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfullyReceivedFramesForMeStat;
        // interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfullyReceivedFramesForSomebodyElseStat;

        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFrameDisposalsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumSuccessfulReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumCorruptedReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as Ieee154NumFailedReceptionCompletionsStat;


        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsPassedForAcceptanceStat;

        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsPassedForForwardingStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsStartedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsStoppedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsFinishedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesAllocatedByForwarderStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesFreedByForwarderStat;

        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsFinishedBeingDefragmentedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesReceivedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesAllocatedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesFreedByDefragmenterStat;

        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsPassedForFragmentationStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsStartedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsStoppedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumPacketsFinishedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesRequestedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesObtainedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesReleasedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumStartedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFinishedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesFragmenterStartedForwardingStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesFragmenterCanceledForwardingStat;
        interface StatsIncrementer<uint8_t> as LoWPANNumFramesFragmenterFinishedForwardingStat;
    }
}
implementation
{
    enum
    {
        MAX_CONCURR_INCOMING_IPV6_PKTS = WHIP6_IPV6_MAX_CONCURRENT_PACKETS - 2,
        MAX_CONCURR_OUTGOING_IPV6_PKTS = WHIP6_IPV6_MAX_CONCURRENT_PACKETS - 2,
        MAX_CONCURR_INCOMING_FRAMES = WHIP6_IEEE154_MAX_CONCURRENT_FRAMES - 2,
        MAX_CONCURR_OUTGOING_FRAMES = WHIP6_IEEE154_MAX_CONCURRENT_FRAMES - 2,
        MAX_CONCURR_FRAG_PKTS = MAX_CONCURR_OUTGOING_IPV6_PKTS,
        MAX_CONCURR_DEFRAG_PKTS = MAX_CONCURR_INCOMING_IPV6_PKTS,
        MAX_OUT_OF_ORDER_FRAG_SPECS_FOR_DEFRAG = 0,
    };

    components PlatformIOVElementAllocatorPub;
    components IPv6PacketPrototypeAllocatorPub;
    components NetStackConfigPub as ConfigPrv;
    components PlatformRandomPub as RandomPrv;
    components CoreIeee154StackPub as Ieee154StackPrv;
    components new GenericLoWPANStackPub(
            MAX_CONCURR_INCOMING_IPV6_PKTS,
            MAX_CONCURR_OUTGOING_IPV6_PKTS,
            MAX_CONCURR_INCOMING_FRAMES,
            MAX_CONCURR_OUTGOING_FRAMES,
            MAX_CONCURR_FRAG_PKTS,
            MAX_CONCURR_DEFRAG_PKTS,
            MAX_OUT_OF_ORDER_FRAG_SPECS_FOR_DEFRAG
    ) as LowpanStackPrv;
    components CoreLoWPANStackGluePrv as GluePrv;

    SynchronousStarter = GluePrv;

#ifdef WHIP6_CORE_LOWPAN_USE_PACKET_JUCTION
    // Packet junction allows you to intercept packets coming
    // from the upper-ipv6-stack. It also allows to inject packets
    // into it.
    components LoWPANPacketJunctionPub as Junct;
    LoWPANIPv6PacketForwarder = Junct.UpperStackForwarder;
    LoWPANIPv6PacketAcceptor = Junct.UpperStackAcceptor;
    Junct.LoWPANRadioAcceptor -> LowpanStackPrv;
    Junct.LoWPANRadioForwarder -> LowpanStackPrv;
#else // No junction
    LoWPANIPv6PacketForwarder = LowpanStackPrv;
    LoWPANIPv6PacketAcceptor = LowpanStackPrv;
#endif  // WHIP6_CORE_LOWPAN_USE_PACKET_JUCTION

    LoWPANLinkTable = Ieee154StackPrv;
    Ieee154LocalAddressProvider = Ieee154StackPrv;

    LowpanStackPrv.LoWPANLinkTable -> Ieee154StackPrv.LinkTable;


    LowpanStackPrv.Ieee154LocalAddressProvider -> Ieee154StackPrv;
    LowpanStackPrv.Ieee154FrameAllocator -> Ieee154StackPrv;
    LowpanStackPrv.Ieee154FrameReceiver -> Ieee154StackPrv;
    LowpanStackPrv.Ieee154FrameSender -> Ieee154StackPrv;
    LowpanStackPrv.Ieee154FrameMetadata -> Ieee154StackPrv;
    LowpanStackPrv.Random -> RandomPrv;
    LowpanStackPrv.LoWPANFragmentReassemblyTimeoutInMillis -> ConfigPrv.LoWPANFragmentReassemblyTimeoutInMillis;
    LowpanStackPrv.LoWPANMaxFrameRetransmissionAttempts -> ConfigPrv.LoWPANMaxFrameRetransmissionAttempts;
    LowpanStackPrv.LoWPANBroadcastTxFailureRollbackDurationInMillis -> ConfigPrv.LoWPANBroadcastTxFailureRollbackDurationInMillis;
    LowpanStackPrv.LoWPANUnicastTxFailureRollbackDurationInMillis -> ConfigPrv.LoWPANUnicastTxFailureRollbackDurationInMillis;
    LowpanStackPrv.LoWPANBroadcastTxSuccessRollbackDurationInMillis -> ConfigPrv.LoWPANBroadcastTxSuccessRollbackDurationInMillis;
    LowpanStackPrv.LoWPANUnicastTxSuccessRollbackDurationInMillis -> ConfigPrv.LoWPANUnicastTxSuccessRollbackDurationInMillis;

    GluePrv.Ieee154StackSynchronousStarter -> Ieee154StackPrv;
    GluePrv.GenericLoWPANStackSynchronousStarter -> LowpanStackPrv;

    // Disabled stats during transistion to RiMAC
    // components CoreMacRadioPub as RadioPrv;
    // RadioPrv.NumSuccessfulRXStat = RadioNumSuccessfulRXStat;
    // RadioPrv.NumSuccessfulTXStat = RadioNumSuccessfulTXStat;
    // RadioPrv.NumLengthErrorsStat = RadioNumLengthErrorsStat;
    // RadioPrv.NumCRCErrorsStat = RadioNumCRCErrorsStat;
    // RadioPrv.NumTXTimeoutErrorsStat = RadioNumTXTimeoutErrorsStat;
    // Ieee154StackPrv.NumSuccessfullyReceivedFramesForMeStat = Ieee154NumSuccessfullyReceivedFramesForMeStat;
    // Ieee154StackPrv.NumSuccessfullyReceivedFramesForSomebodyElseStat = Ieee154NumSuccessfullyReceivedFramesForSomebodyElseStat;

    Ieee154StackPrv.NumSuccessfulFrameAllocsStat = Ieee154NumSuccessfulFrameAllocsStat;
    Ieee154StackPrv.NumFailedFrameAllocsStat = Ieee154NumFailedFrameAllocsStat;
    Ieee154StackPrv.NumFrameDisposalsStat = Ieee154NumFrameDisposalsStat;
    Ieee154StackPrv.NumSuccessfulTransmissionStartsStat = Ieee154NumSuccessfulTransmissionStartsStat;
    Ieee154StackPrv.NumFailedTransmissionStartsStat = Ieee154NumFailedTransmissionStartsStat;
    Ieee154StackPrv.NumSuccessfulTransmissionCancelsStat = Ieee154NumSuccessfulTransmissionCancelsStat;
    Ieee154StackPrv.NumFailedTransmissionCancelsStat = Ieee154NumFailedTransmissionCancelsStat;
    Ieee154StackPrv.NumSuccessfulTransmissionCompletionsStat = Ieee154NumSuccessfulTransmissionCompletionsStat;
    Ieee154StackPrv.NumFailedTransmissionCompletionsStat = Ieee154NumFailedTransmissionCompletionsStat;
    Ieee154StackPrv.NumSuccessfulReceptionStartsStat = Ieee154NumSuccessfulReceptionStartsStat;
    Ieee154StackPrv.NumFailedReceptionStartsStat = Ieee154NumFailedReceptionStartsStat;
    Ieee154StackPrv.NumSuccessfulReceptionCancelsStat = Ieee154NumSuccessfulReceptionCancelsStat;
    Ieee154StackPrv.NumFailedReceptionCancelsStat = Ieee154NumFailedReceptionCancelsStat;
    Ieee154StackPrv.NumSuccessfulReceptionCompletionsStat = Ieee154NumSuccessfulReceptionCompletionsStat;
    Ieee154StackPrv.NumCorruptedReceptionCompletionsStat = Ieee154NumCorruptedReceptionCompletionsStat;
    Ieee154StackPrv.NumFailedReceptionCompletionsStat = Ieee154NumFailedReceptionCompletionsStat;

    LowpanStackPrv.NumPacketsPassedForAcceptanceStat = LoWPANNumPacketsPassedForAcceptanceStat;

    LowpanStackPrv.NumPacketsPassedForForwardingStat = LoWPANNumPacketsPassedForForwardingStat;
    LowpanStackPrv.NumPacketsStartedBeingForwardedStat = LoWPANNumPacketsStartedBeingForwardedStat;
    LowpanStackPrv.NumPacketsStoppedBeingForwardedStat = LoWPANNumPacketsStoppedBeingForwardedStat;
    LowpanStackPrv.NumPacketsFinishedBeingForwardedStat = LoWPANNumPacketsFinishedBeingForwardedStat;
    LowpanStackPrv.NumFramesAllocatedByForwarderStat = LoWPANNumFramesAllocatedByForwarderStat;
    LowpanStackPrv.NumFramesFreedByForwarderStat = LoWPANNumFramesFreedByForwarderStat;

    LowpanStackPrv.NumPacketsFinishedBeingDefragmentedStat = LoWPANNumPacketsFinishedBeingDefragmentedStat;
    LowpanStackPrv.NumFramesReceivedByDefragmenterStat = LoWPANNumFramesReceivedByDefragmenterStat;
    LowpanStackPrv.NumFramesAllocatedByDefragmenterStat = LoWPANNumFramesAllocatedByDefragmenterStat;
    LowpanStackPrv.NumFramesFreedByDefragmenterStat = LoWPANNumFramesFreedByDefragmenterStat;

    LowpanStackPrv.NumPacketsPassedForFragmentationStat = LoWPANNumPacketsPassedForFragmentationStat;
    LowpanStackPrv.NumPacketsStartedBeingFragmentedStat = LoWPANNumPacketsStartedBeingFragmentedStat;
    LowpanStackPrv.NumPacketsStoppedBeingFragmentedStat = LoWPANNumPacketsStoppedBeingFragmentedStat;
    LowpanStackPrv.NumPacketsFinishedBeingFragmentedStat = LoWPANNumPacketsFinishedBeingFragmentedStat;
    LowpanStackPrv.NumFramesRequestedByFragmenterStat = LoWPANNumFramesRequestedByFragmenterStat;
    LowpanStackPrv.NumFramesObtainedByFragmenterStat = LoWPANNumFramesObtainedByFragmenterStat;
    LowpanStackPrv.NumFramesReleasedByFragmenterStat = LoWPANNumFramesReleasedByFragmenterStat;
    LowpanStackPrv.NumStartedInternalFragmenterJobsStat = LoWPANNumStartedInternalFragmenterJobsStat;
    LowpanStackPrv.NumFinishedInternalFragmenterJobsStat = LoWPANNumFinishedInternalFragmenterJobsStat;
    LowpanStackPrv.NumFramesFragmenterStartedForwardingStat = LoWPANNumFramesFragmenterStartedForwardingStat;
    LowpanStackPrv.NumFramesFragmenterCanceledForwardingStat = LoWPANNumFramesFragmenterCanceledForwardingStat;
    LowpanStackPrv.NumFramesFragmenterFinishedForwardingStat = LoWPANNumFramesFragmenterFinishedForwardingStat;
}

