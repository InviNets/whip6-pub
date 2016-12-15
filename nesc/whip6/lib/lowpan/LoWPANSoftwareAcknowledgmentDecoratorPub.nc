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



/**
 * A platform-independent decorator for an
 * IEEE 802.15.4 stack that generates software
 * acknowledgments for all unicast packets that
 * employ 6LoWPAN NALP frames.
 *
 * The decorator should be placed above the
 * decorator for address filtering. For the
 * acknowledgments to work, someone has to
 * invoke frame reception.
 *
 * @author Konrad Iwanicki
 */

generic configuration LoWPANSoftwareAcknowledgmentDecoratorPub()
{
    provides
    {
        interface Ieee154UnpackedDataFrameReceiver as FrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as FrameSender @exactlyonce();
    }
    uses
    {
        interface Ieee154UnpackedDataFrameReceiver as SubFrameReceiver @exactlyonce();
        interface Ieee154UnpackedDataFrameSender as SubFrameSender @exactlyonce();
        interface ConfigValue<uint32_t> as TransmissionAndAcknowledgmentTimeoutInMillis @exactlyonce();
        interface StatsIncrementer<uint8_t> as NumReceivedAcknowledgmentsForOutgoingFramesStat;
        interface StatsIncrementer<uint8_t> as NumMissedAcknowledgmentsForOutgoingFramesStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat;
    }
}
implementation
{
    components new LoWPANSoftwareAcknowledgmentDecoratorPrv() as ImplMainPrv;
    components new BitPub() as AcknowledgmentReceivedBitPrv;
    components new BitPub() as AcknowledgmentMissedBitPrv;
    components new BitPub() as TransmissionFinishedBitPrv;
    components new PlatformTimerMilliPub() as AcknowledgmentTimeoutTimerPrv;
    components Ieee154FrameSequenceNumberGeneratorPub as FrameSequenceNumberGeneratorPrv;
    components Ieee154FrameAllocatorPub as FrameAllocatorPrv;

    FrameReceiver = ImplMainPrv;
    FrameSender = ImplMainPrv;

    ImplMainPrv.SubFrameReceiver = SubFrameReceiver;
    ImplMainPrv.SubFrameSender = SubFrameSender;
    ImplMainPrv.FrameAllocator -> FrameAllocatorPrv;
    ImplMainPrv.FrameSequenceNumberGenerator -> FrameSequenceNumberGeneratorPrv;
    ImplMainPrv.AcknowledgmentTimeoutTimer -> AcknowledgmentTimeoutTimerPrv;
    ImplMainPrv.TransmissionAndAcknowledgmentTimeoutInMillis = TransmissionAndAcknowledgmentTimeoutInMillis;
    ImplMainPrv.AcknowledgmentReceivedBit -> AcknowledgmentReceivedBitPrv;
    ImplMainPrv.AcknowledgmentMissedBit -> AcknowledgmentMissedBitPrv;
    ImplMainPrv.TransmissionFinishedBit -> TransmissionFinishedBitPrv;
    ImplMainPrv.NumReceivedAcknowledgmentsForOutgoingFramesStat = NumReceivedAcknowledgmentsForOutgoingFramesStat;
    ImplMainPrv.NumMissedAcknowledgmentsForOutgoingFramesStat = NumMissedAcknowledgmentsForOutgoingFramesStat;
    ImplMainPrv.NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat = NumSuccessfullyGeneratedAcknowledgmentsForIncomingFramesStat;

}

