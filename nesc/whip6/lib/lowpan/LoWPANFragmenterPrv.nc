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

#include "Ieee154.h"
#include <6lowpan/uc6LoWPANFragmentation.h>



/**
 * The fragmenter of 6LoWPAN frames.
 *
 * @param frag_packet_pool_size The maximal number of
 *   packets that can be concurrently fragmented. The
 *   value must be at least one.
 *
 * @author Konrad Iwanicki
 */
generic configuration LoWPANFragmenterPrv(
    uint8_t frag_packet_pool_size
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANFragmenter as Fragmenter;
    }
    uses
    {
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender @exactlyonce();
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
        FRAG_PACKET_POOL_SIZE = frag_packet_pool_size,
    };

    components new LoWPANFragmenterMainPrv(FRAG_PACKET_POOL_SIZE) as FragmenterMainPrv;
    components new LoWPANFragmenterSendQueueAdapterPrv(FRAG_PACKET_POOL_SIZE) as SendQueueAdapterPrv;
    components new BitPub() as IsOnBitPrv;
    components new BitPub() as IsSendingBitPrv;
    components new WatchedQueuePub(uint8_t, uint8_t, FRAG_PACKET_POOL_SIZE, "JobQueuePrv") as JobQueuePrv;
    components new WatchedQueuePub(whip6_ieee154_dframe_info_t *, uint8_t, FRAG_PACKET_POOL_SIZE, "PacketQueuePrv") as PacketQueuePrv;

    SynchronousStarter = FragmenterMainPrv;
    Fragmenter = FragmenterMainPrv;

    FragmenterMainPrv.IsOnBit -> IsOnBitPrv;
    FragmenterMainPrv.JobQueue -> JobQueuePrv;
    FragmenterMainPrv.Ieee154FrameSender -> SendQueueAdapterPrv;
    FragmenterMainPrv.NumPacketsPassedForFragmentationStat = NumPacketsPassedForFragmentationStat;
    FragmenterMainPrv.NumPacketsStartedBeingFragmentedStat = NumPacketsStartedBeingFragmentedStat;
    FragmenterMainPrv.NumPacketsStoppedBeingFragmentedStat = NumPacketsStoppedBeingFragmentedStat;
    FragmenterMainPrv.NumPacketsFinishedBeingFragmentedStat = NumPacketsFinishedBeingFragmentedStat;
    FragmenterMainPrv.NumFramesRequestedByFragmenterStat = NumFramesRequestedByFragmenterStat;
    FragmenterMainPrv.NumFramesObtainedByFragmenterStat = NumFramesObtainedByFragmenterStat;
    FragmenterMainPrv.NumFramesReleasedByFragmenterStat = NumFramesReleasedByFragmenterStat;
    FragmenterMainPrv.NumStartedInternalFragmenterJobsStat = NumStartedInternalFragmenterJobsStat;
    FragmenterMainPrv.NumFinishedInternalFragmenterJobsStat = NumFinishedInternalFragmenterJobsStat;
    FragmenterMainPrv.NumFramesFragmenterStartedForwardingStat = NumFramesFragmenterStartedForwardingStat;
    FragmenterMainPrv.NumFramesFragmenterCanceledForwardingStat = NumFramesFragmenterCanceledForwardingStat;
    FragmenterMainPrv.NumFramesFragmenterFinishedForwardingStat = NumFramesFragmenterFinishedForwardingStat;
    
    SendQueueAdapterPrv.FrameQueue -> PacketQueuePrv;
    SendQueueAdapterPrv.IsSendingBit -> IsSendingBitPrv;
    SendQueueAdapterPrv.SubIeee154FrameSender = Ieee154FrameSender;
}

