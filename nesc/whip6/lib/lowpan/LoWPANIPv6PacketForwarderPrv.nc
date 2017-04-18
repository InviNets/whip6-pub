/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include <ieee154/ucIeee154AddressTypes.h>
#include <ipv6/ucIpv6PacketTypes.h>



/**
 * The forwarder of IPv6 packets over a
 * 6LoWPAN-compatible network interface.
 *
 * @param max_num_staged_packets The maximal number
 *   of packets that can be enqueued for forwarding.
 * @param max_num_fragmented_packets The maximal number
 *   of packets that can be fragmented and transmitted
 *   concurrently.
 *
 * @author Konrad Iwanicki
 */
generic configuration LoWPANIPv6PacketForwarderPrv(
        uint8_t max_num_staged_packets,
        uint8_t max_num_fragmented_packets
)
{
    provides
    {
        interface SynchronousStarter @exactlyonce();
        interface LoWPANIPv6PacketForwarder as Forwarder @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as FrameSenderForFragmenter @exactlyonce();
    }
    uses
    {
        interface LoWPANFragmenter as Fragmenter @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as LowerFrameSender @exactlyonce();
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator @exactlyonce();
        interface Ieee154LocalAddressProvider @exactlyonce();
        interface LoWPANLinkTable @exactlyonce();
        interface ConfigValue<uint8_t> as MaxFrameRetransmissionAttempts @exactlyonce();
        interface ConfigValue<uint32_t> as BroadcastTxFailureRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as UnicastTxFailureRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as BroadcastTxSuccessRollbackDurationInMillis @exactlyonce();
        interface ConfigValue<uint32_t> as UnicastTxSuccessRollbackDurationInMillis @exactlyonce();
        interface Random;
        interface StatsIncrementer<uint8_t> as NumPacketsPassedForForwardingStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStartedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsStoppedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingForwardedStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByForwarderStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByForwarderStat;
    }
}
implementation
{
    enum
    {
        MAX_NUM_STAGED_PACKETS = max_num_staged_packets,
        MAX_NUM_FRAGMENTED_PACKETS = max_num_fragmented_packets,
    };


    components new BitPub() as IsOnBitPrv;
    components new BitPub() as TxBitPrv;
    components new PlatformTimerMilliPub() as TxTimerPrv;
    components Ieee154FrameSequenceNumberGeneratorPub as Ieee154FrameSequenceNumberGeneratorPrv;
    components new LoWPANIPv6PacketForwarderMainPrv(
            MAX_NUM_STAGED_PACKETS,
            MAX_NUM_FRAGMENTED_PACKETS
    ) as ForwarderMainPrv;


    SynchronousStarter = ForwarderMainPrv;
    Forwarder = ForwarderMainPrv;
    FrameSenderForFragmenter = ForwarderMainPrv;

    ForwarderMainPrv.IsOnBit -> IsOnBitPrv;
    ForwarderMainPrv.TxBit -> TxBitPrv;
    ForwarderMainPrv.Fragmenter = Fragmenter;
    ForwarderMainPrv.SubFrameSender = LowerFrameSender;
    ForwarderMainPrv.FrameAllocator = Ieee154FrameAllocator;
    ForwarderMainPrv.TxTimer -> TxTimerPrv;
    ForwarderMainPrv.Ieee154LocalAddressProvider = Ieee154LocalAddressProvider;
    ForwarderMainPrv.Ieee154FrameSequenceNumberGenerator -> Ieee154FrameSequenceNumberGeneratorPrv;
    ForwarderMainPrv.LoWPANLinkTable = LoWPANLinkTable;
    ForwarderMainPrv.MaxFrameRetransmissionAttempts = MaxFrameRetransmissionAttempts;
    ForwarderMainPrv.BroadcastTxFailureRollbackDuration = BroadcastTxFailureRollbackDurationInMillis;
    ForwarderMainPrv.UnicastTxFailureRollbackDuration = UnicastTxFailureRollbackDurationInMillis;
    ForwarderMainPrv.BroadcastTxSuccessRollbackDuration = BroadcastTxSuccessRollbackDurationInMillis;
    ForwarderMainPrv.UnicastTxSuccessRollbackDuration = UnicastTxSuccessRollbackDurationInMillis;
    ForwarderMainPrv.Random = Random;
    ForwarderMainPrv.NumPacketsPassedForForwardingStat = NumPacketsPassedForForwardingStat;
    ForwarderMainPrv.NumPacketsStartedBeingForwardedStat = NumPacketsStartedBeingForwardedStat;
    ForwarderMainPrv.NumPacketsStoppedBeingForwardedStat = NumPacketsStoppedBeingForwardedStat;
    ForwarderMainPrv.NumPacketsFinishedBeingForwardedStat = NumPacketsFinishedBeingForwardedStat;
    ForwarderMainPrv.NumFramesAllocatedByForwarderStat = NumFramesAllocatedByForwarderStat;
    ForwarderMainPrv.NumFramesFreedByForwarderStat = NumFramesFreedByForwarderStat;
}
