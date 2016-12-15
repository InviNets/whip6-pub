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

#include <6lowpan/uc6LoWPANMeshManipulation.h>
#include "Ieee154.h"


/**
 * A generic 6LoWPAN stack.
 *
 * By connecting the stack to an IEEE 802.15.4 interface,
 * one can obtain a 6LoWPAN-compatible interface.
 *
 * @param max_concurr_incoming_ipv6_pkts   The maximal number of
 *   incoming IPv6 packets that can be processed by the
 *   stack. Must be at least 1.
 * @param max_concurr_outgoing_ipv6_pkts   The maximal number of
 *   outgoing IPv6 packets that can be processed by the
 *   stack. Must be at least 1.
 * @param max_concurr_incoming_frames   The maximal
 *   number of incoming IEEE 802.15.4 frames that can processed
 *   concurrently by the stack. Must be at least 1.
 * @param max_concurr_outgoing_frames   The maximal
 *   number of outgoing IEEE 802.15.4 frames that can processed
 *   concurrently by the stack. Must be at least 1.
 * @param max_concurr_frag_pkts   The maximal number of
 *   IPv6 packets that can be fragmented concurrently.
 *   Must be at least 1.
 * @param max_concurr_defrag_pkts   The maximal number of
 *   IPv6 packets that can be defragmented concurrently.
 *   A value of 0 means that all IPv6 packets must fit
 *   a single IEEE 802.15.4 frame without any 6LoWPAN
 *   fragmentation header.
 * @param max_out_of_order_frag_specs_for_defrag   The
 *   maximal number of 6LoWPAN IPv6 packet fragment
 *   specifications that allow for defragmenting packets
 *   from pieces that come out of order. A value of 0
 *   means that no out of order defragmentation is possible.
 *
 * @author Konrad Iwanicki
 */
generic configuration GenericLoWPANStackPub(
        uint8_t max_concurr_incoming_ipv6_pkts, // probably unused
        uint8_t max_concurr_outgoing_ipv6_pkts,
        uint8_t max_concurr_incoming_frames,
        uint8_t max_concurr_outgoing_frames, // probably unused
        uint8_t max_concurr_frag_pkts,
        uint8_t max_concurr_defrag_pkts,
        uint8_t max_out_of_order_frag_specs_for_defrag
)
{
    provides
    {
        interface SynchronousStarter @atleastonce();
        interface LoWPANIPv6PacketForwarder @exactlyonce();
        interface LoWPANIPv6PacketAcceptor @exactlyonce();
    }
    uses
    {
        interface LoWPANLinkTable;
        interface Ieee154LocalAddressProvider @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator @exactlyonce();
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender @exactlyonce();
        interface Ieee154UnpackedDataFrameMetadata as Ieee154FrameMetadata @exactlyonce();
        interface Random;

        interface ConfigValue<uint32_t> as LoWPANFragmentReassemblyTimeoutInMillis @exactlyonce();
        interface ConfigValue<uint8_t> as LoWPANMaxFrameRetransmissionAttempts @exactlyonce();
        interface ConfigValue<uint32_t> as LoWPANBroadcastTxFailureRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as LoWPANUnicastTxFailureRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as LoWPANBroadcastTxSuccessRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as LoWPANUnicastTxSuccessRollbackDurationInMillis @exactlyonce();

        interface StatsIncrementer<uint8_t> as NumPacketsPassedForAcceptanceStat;

        interface StatsIncrementer<uint8_t> as NumPacketsPassedForForwardingStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStartedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStoppedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByForwarderStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByForwarderStat;

        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingDefragmentedStat;
        interface StatsIncrementer<uint8_t> as NumFramesReceivedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByDefragmenterStat;

        interface StatsIncrementer<uint8_t> as NumPacketsPassedForFragmentationStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStartedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStoppedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingFragmentedStat;
        interface StatsIncrementer<uint8_t> as NumFramesRequestedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesObtainedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesReleasedByFragmenterStat;
        interface StatsIncrementer<uint8_t> as NumStartedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as NumFinishedInternalFragmenterJobsStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterStartedForwardingStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterCanceledForwardingStat;
        interface StatsIncrementer<uint8_t> as NumFramesFragmenterFinishedForwardingStat;
    }
}
implementation
{
    enum
    {
        MAX_CONCURR_INCOMING_IPV6_PKTS = max_concurr_incoming_ipv6_pkts,
        MAX_CONCURR_OUTGOING_IPV6_PKTS = max_concurr_outgoing_ipv6_pkts,
        MAX_CONCURR_INCOMING_FRAMES = max_concurr_incoming_frames,
        MAX_CONCURR_OUTGOING_FRAMES = max_concurr_outgoing_frames,
        MAC_CONCURR_FRAG_PKTS = max_concurr_frag_pkts,
        MAC_CONCURR_DEFRAG_PKTS = max_concurr_defrag_pkts,
        MAX_OUT_OF_ORDER_FRAG_SPECS_FOR_DEFRAG = max_out_of_order_frag_specs_for_defrag,
    };

    components new LoWPANDefragmenterPrv(
            MAC_CONCURR_DEFRAG_PKTS,
            MAX_OUT_OF_ORDER_FRAG_SPECS_FOR_DEFRAG,
            MAX_CONCURR_INCOMING_FRAMES
    ) as DefragmenterPrv;
    components new LoWPANIPv6PacketForwarderPrv(
            MAX_CONCURR_OUTGOING_IPV6_PKTS,
            MAC_CONCURR_FRAG_PKTS
    ) as ForwarderPrv;
    components new LoWPANFragmenterPrv(
            MAC_CONCURR_FRAG_PKTS
    ) as FragmenterPrv;
    components new LoWPANStackGluePrv(
    ) as GluePrv;

    SynchronousStarter = GluePrv;
    LoWPANIPv6PacketForwarder = ForwarderPrv;
    LoWPANIPv6PacketAcceptor = GluePrv;

    GluePrv.DefragmenterStarter -> DefragmenterPrv;
    GluePrv.ForwarderStarter -> ForwarderPrv;
    GluePrv.FragmenterStarter -> FragmenterPrv;
    GluePrv.LoWPANDefragmenter -> DefragmenterPrv;
    GluePrv.NumPacketsPassedForAcceptanceStat = NumPacketsPassedForAcceptanceStat;

    DefragmenterPrv.Ieee154FrameAllocator = Ieee154FrameAllocator;
    DefragmenterPrv.Ieee154FrameReceiver = Ieee154FrameReceiver;
    DefragmenterPrv.Ieee154UnpackedDataFrameMetadata = Ieee154FrameMetadata;
    DefragmenterPrv.LoWPANLinkTable = LoWPANLinkTable;
    DefragmenterPrv.ReassemblyTimeoutInMillis = LoWPANFragmentReassemblyTimeoutInMillis;
    DefragmenterPrv.NumPacketsFinishedBeingDefragmentedStat = NumPacketsFinishedBeingDefragmentedStat;
    DefragmenterPrv.NumFramesReceivedByDefragmenterStat = NumFramesReceivedByDefragmenterStat;
    DefragmenterPrv.NumFramesAllocatedByDefragmenterStat = NumFramesAllocatedByDefragmenterStat;
    DefragmenterPrv.NumFramesFreedByDefragmenterStat = NumFramesFreedByDefragmenterStat;

    FragmenterPrv.Ieee154FrameSender -> ForwarderPrv.FrameSenderForFragmenter;
    FragmenterPrv.NumPacketsPassedForFragmentationStat = NumPacketsPassedForFragmentationStat;
    FragmenterPrv.NumPacketsStartedBeingFragmentedStat = NumPacketsStartedBeingFragmentedStat;
    FragmenterPrv.NumPacketsStoppedBeingFragmentedStat = NumPacketsStoppedBeingFragmentedStat;
    FragmenterPrv.NumPacketsFinishedBeingFragmentedStat = NumPacketsFinishedBeingFragmentedStat;
    FragmenterPrv.NumFramesRequestedByFragmenterStat = NumFramesRequestedByFragmenterStat;
    FragmenterPrv.NumFramesObtainedByFragmenterStat = NumFramesObtainedByFragmenterStat;
    FragmenterPrv.NumFramesReleasedByFragmenterStat = NumFramesReleasedByFragmenterStat;
    FragmenterPrv.NumStartedInternalFragmenterJobsStat = NumStartedInternalFragmenterJobsStat;
    FragmenterPrv.NumFinishedInternalFragmenterJobsStat = NumFinishedInternalFragmenterJobsStat;
    FragmenterPrv.NumFramesFragmenterStartedForwardingStat = NumFramesFragmenterStartedForwardingStat;
    FragmenterPrv.NumFramesFragmenterCanceledForwardingStat = NumFramesFragmenterCanceledForwardingStat;
    FragmenterPrv.NumFramesFragmenterFinishedForwardingStat = NumFramesFragmenterFinishedForwardingStat;

    ForwarderPrv.Fragmenter -> FragmenterPrv;
    ForwarderPrv.LowerFrameSender = Ieee154FrameSender;
    ForwarderPrv.Ieee154FrameAllocator = Ieee154FrameAllocator;
    ForwarderPrv.Ieee154LocalAddressProvider = Ieee154LocalAddressProvider;
    ForwarderPrv.LoWPANLinkTable = LoWPANLinkTable;
    ForwarderPrv.MaxFrameRetransmissionAttempts = LoWPANMaxFrameRetransmissionAttempts;
    ForwarderPrv.BroadcastTxFailureRollbackDurationInMillis = LoWPANBroadcastTxFailureRollbackDurationInMillis;
    ForwarderPrv.UnicastTxFailureRollbackDurationInMillis = LoWPANUnicastTxFailureRollbackDurationInMillis;
    ForwarderPrv.BroadcastTxSuccessRollbackDurationInMillis = LoWPANBroadcastTxSuccessRollbackDurationInMillis;
    ForwarderPrv.UnicastTxSuccessRollbackDurationInMillis = LoWPANUnicastTxSuccessRollbackDurationInMillis;
    ForwarderPrv.Random = Random;
    ForwarderPrv.NumPacketsPassedForForwardingStat = NumPacketsPassedForForwardingStat;
    ForwarderPrv.NumPacketsStartedBeingForwardedStat = NumPacketsStartedBeingForwardedStat;
    ForwarderPrv.NumPacketsStoppedBeingForwardedStat = NumPacketsStoppedBeingForwardedStat;
    ForwarderPrv.NumPacketsFinishedBeingForwardedStat = NumPacketsFinishedBeingForwardedStat;
    ForwarderPrv.NumFramesAllocatedByForwarderStat = NumFramesAllocatedByForwarderStat;
    ForwarderPrv.NumFramesFreedByForwarderStat = NumFramesFreedByForwarderStat;
}

