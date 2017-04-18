/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#include "NetStackCompileTimeConfig.h"
#include "Ieee154.h"
#include "PlatformFrame.h"

/**
 * An entire IEEE 802.15.4 radio stack for
 * WhisperCore-based platforms.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 */
configuration CoreIeee154StackPub
{
    provides
    {
        interface SynchronousStarter;
        interface Ieee154LocalAddressProvider;
        interface Ieee154UnpackedDataFrameAllocator as Ieee154FrameAllocator;
        interface Ieee154UnpackedDataFrameMetadata as Ieee154FrameMetadata;
        interface Ieee154UnpackedDataFrameSender as Ieee154FrameSender;
        interface Ieee154UnpackedDataFrameReceiver as Ieee154FrameReceiver;
        interface LoWPANLinkTable as LinkTable;

#ifndef WHIP6_IEEE154_OLD_STACK
        interface RiMACScan;
        interface RiMACPassiveReceive;
        interface RiMACLongListenCredits;
#endif /* WHIP6_IEEE154_OLD_STACK */

#ifdef WHIP6_IEEE154_ADDRESS_CONFIGURABLE
        interface Ieee154ConfigureAddress;
#endif  // WHIP6_IEEE154_ADDRESS_CONFIGURABLE
    }
    uses
    {
        interface StatsIncrementer<uint8_t> as NumSuccessfulFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFailedFrameAllocsStat;
        interface StatsIncrementer<uint8_t> as NumFrameDisposalsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionStartsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumFailedTransmissionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionStartsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionCancelsStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfulReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumCorruptedReceptionCompletionsStat;
        interface StatsIncrementer<uint8_t> as NumFailedReceptionCompletionsStat;


#ifdef WHIP6_IEEE154_OLD_STACK // TODO better to report this rather then ifdef it
        interface StatsIncrementer<uint8_t> as NumSuccessfullyReceivedFramesForMeStat;
        interface StatsIncrementer<uint8_t> as NumSuccessfullyReceivedFramesForSomebodyElseStat;
#endif /* WHIP6_IEEE154_OLD_STACK */

    }
}
implementation
{
    enum
    {
        FRAME_POOL_SIZE = WHIP6_IEEE154_MAX_CONCURRENT_FRAMES,
    };

    components new GenericObjectPoolPub(platform_frame_t, FRAME_POOL_SIZE) as RawFramePoolPrv;

    components PlatformFrameToIeee154FrameAdapterPrv as RawToIeee154AdapterPrv;
    RawToIeee154AdapterPrv.PlatformFrameAllocator -> RawFramePoolPrv;
    RawToIeee154AdapterPrv.NumSuccessfulFrameAllocsStat = NumSuccessfulFrameAllocsStat;
    RawToIeee154AdapterPrv.NumFailedFrameAllocsStat = NumFailedFrameAllocsStat;
    RawToIeee154AdapterPrv.NumFrameDisposalsStat = NumFrameDisposalsStat;
    RawToIeee154AdapterPrv.NumSuccessfulTransmissionStartsStat = NumSuccessfulTransmissionStartsStat;
    RawToIeee154AdapterPrv.NumFailedTransmissionStartsStat = NumFailedTransmissionStartsStat;
    RawToIeee154AdapterPrv.NumSuccessfulTransmissionCancelsStat = NumSuccessfulTransmissionCancelsStat;
    RawToIeee154AdapterPrv.NumFailedTransmissionCancelsStat = NumFailedTransmissionCancelsStat;
    RawToIeee154AdapterPrv.NumSuccessfulTransmissionCompletionsStat = NumSuccessfulTransmissionCompletionsStat;
    RawToIeee154AdapterPrv.NumFailedTransmissionCompletionsStat = NumFailedTransmissionCompletionsStat;
    RawToIeee154AdapterPrv.NumSuccessfulReceptionStartsStat = NumSuccessfulReceptionStartsStat;
    RawToIeee154AdapterPrv.NumFailedReceptionStartsStat = NumFailedReceptionStartsStat;
    RawToIeee154AdapterPrv.NumSuccessfulReceptionCancelsStat = NumSuccessfulReceptionCancelsStat;
    RawToIeee154AdapterPrv.NumFailedReceptionCancelsStat = NumFailedReceptionCancelsStat;
    RawToIeee154AdapterPrv.NumSuccessfulReceptionCompletionsStat = NumSuccessfulReceptionCompletionsStat;
    RawToIeee154AdapterPrv.NumCorruptedReceptionCompletionsStat = NumCorruptedReceptionCompletionsStat;
    RawToIeee154AdapterPrv.NumFailedReceptionCompletionsStat = NumFailedReceptionCompletionsStat;
    Ieee154FrameMetadata = RawToIeee154AdapterPrv;

#ifdef WHIP6_IEEE154_ADDRESS_CONFIGURABLE
    components new RuntimeConfigurableLocalIeee154AddressPub() as Ieee154Address;
    Ieee154ConfigureAddress = Ieee154Address;
#else
    components LocalIeee154AddressProviderPub as Ieee154Address;
#endif  // WHIP6_IEEE154_ADDRESS_CONFIGURABLE

    Ieee154LocalAddressProvider = Ieee154Address;


    components Ieee154KnownPassiveListnersPub;

    components Ieee154FrameAllocatorPub as GenericIeee154FrameAllocatorPrv;
    Ieee154FrameAllocator = GenericIeee154FrameAllocatorPrv;
    GenericIeee154FrameAllocatorPrv.PlatformSpecificInit -> RawFramePoolPrv;
    GenericIeee154FrameAllocatorPrv.PlatformSpecificAllocator -> RawToIeee154AdapterPrv;

    components new LoWPANLinkTablePrv(
            WHIP6_LOWPAN_MAX_NUM_LINK_TABLE_ENTRIES,
            WHIP6_LOWPAN_NUM_LINK_TABLE_EXT_ADDR_HASH_BUCKETS,
            WHIP6_LOWPAN_NUM_LINK_TABLE_SHORT_ADDR_HASH_BUCKETS
    ) as LinkTablePrv;
    LinkTable = LinkTablePrv;

#ifndef WHIP6_IEEE154_OLD_STACK
    //--------------------------------------------------------------------------
    // RiMAC only stack
    //--------------------------------------------------------------------------
    components CoreRawRadioPub;
    RawToIeee154AdapterPrv.RawFrame -> CoreRawRadioPub;
    RawToIeee154AdapterPrv.RawFrameLQI -> CoreRawRadioPub;
    RawToIeee154AdapterPrv.RawFrameRSSI -> CoreRawRadioPub;


    components RiMACPrv;
    RiMACPrv.RawFrame -> CoreRawRadioPub;
    RiMACPrv.RawFrameSender -> CoreRawRadioPub;
    RiMACPrv.RawFrameReceiver -> CoreRawRadioPub;
    RiMACPrv.CoreRadioReceivingNow -> CoreRawRadioPub;
    RiMACPrv.RawFrameRSSI -> CoreRawRadioPub;
    RiMACPrv.Ieee154KnownPassiveListners -> Ieee154KnownPassiveListnersPub.PassiveListnersInfo;
    RiMACPrv.CoreRadioSimpleAutoACK -> CoreRawRadioPub;
    RiMACScan = RiMACPrv;
    RiMACPassiveReceive = RiMACPrv;
    RiMACLongListenCredits = RiMACPrv;

    Ieee154FrameSender = RiMACPrv;
    Ieee154FrameReceiver = RiMACPrv;
    RiMACPrv.Ieee154FrameAllocator -> GenericIeee154FrameAllocatorPrv;

    components HalRadioTimestampingPub;
    RiMACPrv.RawFrameTimestamp -> HalRadioTimestampingPub;

    RiMACPrv.MyAddress -> Ieee154Address;

    components PlatformRandomPub;
    RiMACPrv.PseudoRandom -> PlatformRandomPub;
    RiMACPrv.LinkTable -> LinkTablePrv;

    components new InitToSynchronousStarterPub() as Starter;
    SynchronousStarter = Starter;

    Starter.Init -> CoreRawRadioPub;
    Starter.Init -> LinkTablePrv;

#else /* WHIP6_IEEE154_OLD_STACK */
    //--------------------------------------------------------------------------
    // No MAC or XMAC stack
    //--------------------------------------------------------------------------

    components new Ieee154FrameReceiverLocalOnlyDestinationAddressFilterDecoratorPub() as DestinationAddrFilterPrv;
    components CoreMacRadioPub as MacRadioPrv;
    RawToIeee154AdapterPrv.RawFrame -> MacRadioPrv;
    RawToIeee154AdapterPrv.RawFrameSender -> MacRadioPrv;
    RawToIeee154AdapterPrv.RawFrameReceiver -> MacRadioPrv;
    RawToIeee154AdapterPrv.RawFrameLQI -> MacRadioPrv;
    RawToIeee154AdapterPrv.RawFrameRSSI -> MacRadioPrv;
    components CoreIeee154StackGluePrv as GluePrv;

    SynchronousStarter = GluePrv;
#ifdef WHIP6_IEEE154_NO_RADIO_RECEPTION
    components new CoreIeee154TxOnlyRadioAdapterPrv() as RadioReceptionOffAdapterPrv;
    Ieee154FrameSender = RadioReceptionOffAdapterPrv;
    Ieee154FrameReceiver = RadioReceptionOffAdapterPrv;
    RadioReceptionOffAdapterPrv.SubIeee154FrameSender -> RawToIeee154AdapterPrv;
    RadioReceptionOffAdapterPrv.SubIeee154FrameReceiver -> DestinationAddrFilterPrv;
#else
    Ieee154FrameSender = RawToIeee154AdapterPrv;
    Ieee154FrameReceiver = DestinationAddrFilterPrv;
#endif // WHIP6_IEEE154_NO_RADIO_RECEPTION


    DestinationAddrFilterPrv.SubFrameReceiver -> RawToIeee154AdapterPrv;
    DestinationAddrFilterPrv.AddressProvider -> Ieee154Address;
    DestinationAddrFilterPrv.NumSuccessfullyReceivedFramesForMeStat = NumSuccessfullyReceivedFramesForMeStat;
    DestinationAddrFilterPrv.NumSuccessfullyReceivedFramesForSomebodyElseStat = NumSuccessfullyReceivedFramesForSomebodyElseStat;

    GluePrv.RadioInit -> MacRadioPrv;
    GluePrv.RadioInit -> LinkTablePrv;
    GluePrv.XMACControl -> MacRadioPrv;
#endif /* WHIP6_IEEE154_OLD_STACK */
}
