/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "Ieee154.h"
#include "TimerTypes.h"
#include <6lowpan/uc6LoWPANDefragmentation.h>


/**
 * A defragmenter of 6LoWPAN frames.
 *
 * @param defrag_packet_pool_size The maximal number of
 *   packets that can be concurrently defragmented. Zero
 *   means that all packets must fit in a single frame.
 * @param frag_spec_pool_size The maximal number of
 *   packet fragments specifications that allow for
 *   defragmenting packets from pieces that come out
 *   of order. Zero means that no out of order
 *   defragmentation is possible.
 * @param frame_queue_size The maximal number of
 *   frames that can be queued for processing while
 *   another frame is being processed.
 *
 * @author Konrad Iwanicki
 */
generic configuration LoWPANDefragmenterPrv(
    uint8_t defrag_packet_pool_size,
    uint8_t frag_spec_pool_size,
    uint8_t frame_queue_size
)
{
    provides
    {
        interface SynchronousStarter;
        interface LoWPANDefragmenter as Defragmenter;
    }
    uses
    {
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator @exactlyonce();
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameMetadata;
        interface LoWPANLinkTable;
        interface ConfigValue<uint32_t> as ReassemblyTimeoutInMillis @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumPacketsFinishedBeingDefragmentedStat;
        interface StatsIncrementer<uint8_t> as NumFramesReceivedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesAllocatedByDefragmenterStat;
        interface StatsIncrementer<uint8_t> as NumFramesFreedByDefragmenterStat;
    }
}
implementation
{
    enum
    {
        DEFRAG_PACKET_POOL_SIZE = defrag_packet_pool_size,
        FRAG_SPEC_POOL_SIZE = frag_spec_pool_size,
        FRAME_QUEUE_SIZE = frame_queue_size,
    };

    components new LoWPANDefragmenterMainPrv(DEFRAG_PACKET_POOL_SIZE, FRAG_SPEC_POOL_SIZE) as DefragmenterMainPrv;
    components new BitPub() as IsOnBitPrv;
    components new BitPub() as TimeoutPendingBitPrv;
    components new WatchedQueuePub(whip6_ieee154_dframe_info_t *, uint8_t, FRAME_QUEUE_SIZE, "FrameQueuePrv") as FrameQueuePrv;
    components new PlatformTimerMilliPub() as ReassemblyTimeoutTimerPrv;

    SynchronousStarter = DefragmenterMainPrv;
    Defragmenter = DefragmenterMainPrv;

    DefragmenterMainPrv.IsOnBit -> IsOnBitPrv;
    DefragmenterMainPrv.TimeoutPendingBit -> TimeoutPendingBitPrv;
    DefragmenterMainPrv.Ieee154FrameAllocator = Ieee154FrameAllocator;
    DefragmenterMainPrv.Ieee154FrameReceiver = Ieee154FrameReceiver;
    DefragmenterMainPrv.Ieee154UnpackedDataFrameMetadata = Ieee154UnpackedDataFrameMetadata;
    DefragmenterMainPrv.LoWPANLinkTable = LoWPANLinkTable;
    DefragmenterMainPrv.Ieee154FrameQueue -> FrameQueuePrv;
    DefragmenterMainPrv.ReassemblyTimeoutTimer -> ReassemblyTimeoutTimerPrv;
    DefragmenterMainPrv.ReassemblyTimeoutInMillis = ReassemblyTimeoutInMillis;
    DefragmenterMainPrv.NumPacketsFinishedBeingDefragmentedStat = NumPacketsFinishedBeingDefragmentedStat;
    DefragmenterMainPrv.NumFramesReceivedByDefragmenterStat = NumFramesReceivedByDefragmenterStat;
    DefragmenterMainPrv.NumFramesAllocatedByDefragmenterStat = NumFramesAllocatedByDefragmenterStat;
    DefragmenterMainPrv.NumFramesFreedByDefragmenterStat = NumFramesFreedByDefragmenterStat;
}
