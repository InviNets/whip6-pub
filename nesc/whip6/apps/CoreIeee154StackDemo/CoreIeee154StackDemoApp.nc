/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "CoreIeee154StackDemo.h"



/**
 * An application demonstrating the IEEE 802.15.4
 * stack on platforms compatible with WhisperCore.
 *
 * @author Konrad Iwanicki
 */
configuration CoreIeee154StackDemoApp
{
}
implementation
{
    components CoreIeee154StackDemoPrv as AppPrv;
    components CoreIeee154StackPub as StackPrv;
    // components CoreMacRadioPub as RadioPrv;
    components LocalIeee154AddressProviderPub as Ieee154AddressProviderPrv;
    components new PlatformTimerMilliPub() as BeaconTimerPrv;
    components new PlatformTimerMilliPub() as TargetTimerPrv;
    components new PlatformTimerMilliPub() as StatsTimerPrv;
    components PlatformRandomPub as RandomPrv;
    components BoardStartupPub;
    components new GenericCommonObjectPrinterPub() as ObjPrinterPrv;
    components GlobalStat32BitRegistryPub as AllStatsPrv;

    AppPrv.Boot -> BoardStartupPub;
    AppPrv.Ieee154StackStart -> StackPrv;
    AppPrv.Ieee154FrameAllocator -> StackPrv;
#ifndef DEMO_NO_SOFTWARE_ACKS
    components new LoWPANSoftwareAcknowledgmentDecoratorPub() as SoftwareAckDecoratorPrv;
    AppPrv.Ieee154FrameReceiver -> SoftwareAckDecoratorPrv;
    AppPrv.Ieee154FrameSender -> SoftwareAckDecoratorPrv;
    SoftwareAckDecoratorPrv.SubFrameReceiver -> StackPrv;
    SoftwareAckDecoratorPrv.SubFrameSender -> StackPrv;
    SoftwareAckDecoratorPrv.TransmissionAndAcknowledgmentTimeoutInMillis -> AppPrv.TransmissionAndAcknowledgmentTimeoutInMillis;
#else
    AppPrv.Ieee154FrameReceiver -> StackPrv;
    AppPrv.Ieee154FrameSender -> StackPrv;
#endif
    AppPrv.Ieee154LocalAddressProvider -> Ieee154AddressProviderPrv;
    AppPrv.BeaconTimer -> BeaconTimerPrv;
    AppPrv.TargetTimer -> TargetTimerPrv;
    AppPrv.StatsTimer -> StatsTimerPrv;
    AppPrv.Random -> RandomPrv;
    AppPrv.CommonObjectPrinter -> ObjPrinterPrv;
    AppPrv.StatsRegistry -> AllStatsPrv;

    // ***************************** STATISTICS ****************************

    // Not provided by the new stack
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "RADIO::NumSuccessfulRXStat",
    //         0
    // ) as NumSuccessfulRXStat;
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "RADIO::NumSuccessfulTXStat",
    //         0
    // ) as NumSuccessfulTXStat;
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "RADIO::NumLengthErrorsStat",
    //         0
    // ) as NumLengthErrorsStat;
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "RADIO::NumCRCErrorsStat",
    //         0
    // ) as NumCRCErrorsStat;
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "RADIO::NumTXTimeoutErrorsStat",
    //         0
    // ) as NumTXTimeoutErrorsStat;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulFrameAllocsStat",
            0
    ) as NumSuccessfulFrameAllocsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedFrameAllocsStat",
            0
    ) as NumFailedFrameAllocsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFrameDisposalsStat",
            0
    ) as NumFrameDisposalsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulTransmissionStartsStat",
            0
    ) as NumSuccessfulTransmissionStartsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedTransmissionStartsStat",
            0
    ) as NumFailedTransmissionStartsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulTransmissionCancelsStat",
            0
    ) as NumSuccessfulTransmissionCancelsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedTransmissionCancelsStat",
            0
    ) as NumFailedTransmissionCancelsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulTransmissionCompletionsStat",
            0
    ) as NumSuccessfulTransmissionCompletionsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedTransmissionCompletionsStat",
            0
    ) as NumFailedTransmissionCompletionsStatPrv;

    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulReceptionStartsStat",
            0
    ) as NumSuccessfulReceptionStartsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedReceptionStartsStat",
            0
    ) as NumFailedReceptionStartsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulReceptionCancelsStat",
            0
    ) as NumSuccessfulReceptionCancelsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedReceptionCancelsStat",
            0
    ) as NumFailedReceptionCancelsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumSuccessfulReceptionCompletionsStat",
            0
    ) as NumSuccessfulReceptionCompletionsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumCorruptedReceptionCompletionsStat",
            0
    ) as NumCorruptedReceptionCompletionsStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "IEEE154::NumFailedReceptionCompletionsStat",
            0
    ) as NumFailedReceptionCompletionsStatPrv;
    // These stats are not provided
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "IEEE154::NumSuccessfullyReceivedFramesForMeStat",
    //         0
    // ) as NumSuccessfullyReceivedFramesForMeStatPrv;
    // components new GlobalStat32BitPub(
    //         unique(DEMO_STAT_INDEXING_STR),
    //         "IEEE154::NumSuccessfullyReceivedFramesForSomebodyElseStat",
    //         0
    // ) as NumSuccessfullyReceivedFramesForSomebodyElseStatPrv;

    // Not provided by the new stack
    // RadioPrv.NumSuccessfulRXStat -> NumSuccessfulRXStat;
    // RadioPrv.NumSuccessfulTXStat -> NumSuccessfulTXStat;
    // RadioPrv.NumLengthErrorsStat -> NumLengthErrorsStat;
    // RadioPrv.NumCRCErrorsStat -> NumCRCErrorsStat;
    // RadioPrv.NumTXTimeoutErrorsStat -> NumTXTimeoutErrorsStat;
    StackPrv.NumSuccessfulFrameAllocsStat -> NumSuccessfulFrameAllocsStatPrv;
    StackPrv.NumFailedFrameAllocsStat -> NumFailedFrameAllocsStatPrv;
    StackPrv.NumFrameDisposalsStat -> NumFrameDisposalsStatPrv;
    StackPrv.NumSuccessfulTransmissionStartsStat -> NumSuccessfulTransmissionStartsStatPrv;
    StackPrv.NumFailedTransmissionStartsStat -> NumFailedTransmissionStartsStatPrv;
    StackPrv.NumSuccessfulTransmissionCancelsStat -> NumSuccessfulTransmissionCancelsStatPrv;
    StackPrv.NumFailedTransmissionCancelsStat -> NumFailedTransmissionCancelsStatPrv;
    StackPrv.NumSuccessfulTransmissionCompletionsStat -> NumSuccessfulTransmissionCompletionsStatPrv;
    StackPrv.NumFailedTransmissionCompletionsStat -> NumFailedTransmissionCompletionsStatPrv;
    StackPrv.NumSuccessfulReceptionStartsStat -> NumSuccessfulReceptionStartsStatPrv;
    StackPrv.NumFailedReceptionStartsStat -> NumFailedReceptionStartsStatPrv;
    StackPrv.NumSuccessfulReceptionCancelsStat -> NumSuccessfulReceptionCancelsStatPrv;
    StackPrv.NumFailedReceptionCancelsStat -> NumFailedReceptionCancelsStatPrv;
    StackPrv.NumSuccessfulReceptionCompletionsStat -> NumSuccessfulReceptionCompletionsStatPrv;
    StackPrv.NumCorruptedReceptionCompletionsStat -> NumCorruptedReceptionCompletionsStatPrv;
    StackPrv.NumFailedReceptionCompletionsStat -> NumFailedReceptionCompletionsStatPrv;
    // These stats are not provided.
    // StackPrv.NumSuccessfullyReceivedFramesForMeStat -> NumSuccessfullyReceivedFramesForMeStatPrv;
    // StackPrv.NumSuccessfullyReceivedFramesForSomebodyElseStat -> NumSuccessfullyReceivedFramesForSomebodyElseStatPrv;

#ifndef DEMO_NO_SOFTWARE_ACKS
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "6LOWPAN::NumReceivedAcknowledgmentsForOutgoingFramesStat",
            0
    ) as NumReceivedAcknowledgmentsForOutgoingFramesStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "6LOWPAN::NumMissedAcknowledgmentsForOutgoingFramesStat",
            0
    ) as NumMissedAcknowledgmentsForOutgoingFramesStatPrv;
    components new GlobalStat32BitPub(
            unique(DEMO_STAT_INDEXING_STR),
            "6LOWPAN::NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat",
            0
    ) as NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStatPrv;
    SoftwareAckDecoratorPrv.NumReceivedAcknowledgmentsForOutgoingFramesStat -> NumReceivedAcknowledgmentsForOutgoingFramesStatPrv;
    SoftwareAckDecoratorPrv.NumMissedAcknowledgmentsForOutgoingFramesStat -> NumMissedAcknowledgmentsForOutgoingFramesStatPrv;
    SoftwareAckDecoratorPrv.NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat -> NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStatPrv;
#endif

}
