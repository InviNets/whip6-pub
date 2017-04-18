/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration HalRadioPub {
    provides interface Init;
    provides interface RawFrame;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface RawFrameRSSI;
    provides interface RawFrameLQI;
    provides interface RawFrameCRC;
    provides interface RawFrameTimestamp<T32khz>;
    provides interface RawRSSI;
    provides interface CoreRadioReceivingNow;
    provides interface CoreRadioSimpleAutoACK;
    provides interface CoreRadioCRCFiltering;
    provides interface RawBLEAdvertiser;
    provides interface RawBLEScanner;

    uses interface Init as InitAfterRadio;

    uses interface BLEAddressProvider;

    uses interface Led as RadioOnLed;

    uses interface AsyncStatsIncrementer<uint8_t> as NumRadioInterruptsStat;
    uses interface AsyncStatsIncrementer<uint8_t> as NumErrorInterruptsStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulRXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulTXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulBLEAdvTXStat;
    uses interface StatsIncrementer<uint8_t> as NumLengthErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumCRCErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumTXTimeoutErrorsStat;
}
implementation {
    components RFCoreRadioPrv;
    components RFCorePrv;

    RFCoreRadioPrv.RFCore -> RFCorePrv;

    components HplRFCoreInterruptsPub as Ints;
    RFCorePrv.CPE0Int -> Ints.RFCCPE0;
    RFCorePrv.CPE1Int -> Ints.RFCCPE1;

    components CC26xxPowerDomainsPub;
    RFCorePrv.PowerDomain -> CC26xxPowerDomainsPub.RFCoreDomain;

#if CC26XX_XOSC_HF_ALWAYS_ON
    components RFCoreDummyXOSCPrv as XOSC;
#else
    components RFCoreXOSCPrv as XOSC;
#endif
    RFCoreRadioPrv.RFCoreXOSC -> XOSC;

    components new HalAskBeforeSleepPub();
    RFCoreRadioPrv.AskBeforeSleep -> HalAskBeforeSleepPub;

    RFCoreRadioPrv.NumRadioInterruptsStat = NumRadioInterruptsStat;
    RFCoreRadioPrv.NumErrorInterruptsStat = NumErrorInterruptsStat;
    RFCoreRadioPrv.NumSuccessfulRXStat = NumSuccessfulRXStat;
    RFCoreRadioPrv.NumSuccessfulTXStat = NumSuccessfulTXStat;
    RFCoreRadioPrv.NumSuccessfulBLEAdvTXStat = NumSuccessfulBLEAdvTXStat;
    RFCoreRadioPrv.NumLengthErrorsStat = NumLengthErrorsStat;
    RFCoreRadioPrv.NumCRCErrorsStat = NumCRCErrorsStat;
    RFCoreRadioPrv.NumTXTimeoutErrorsStat = NumTXTimeoutErrorsStat;

    components new PlatformTimerMilliPub() as TXWatchdogTimer;
    RFCoreRadioPrv.TXWatchdogTimer -> TXWatchdogTimer;

    components new PlatformTimerMilliPub() as BLEAdvWatchdogTimer;
    RFCoreRadioPrv.BLEAdvWatchdogTimer -> BLEAdvWatchdogTimer;

    components BusyWaitProviderPub;
    RFCoreRadioPrv.BusyWait -> BusyWaitProviderPub;

    Init = RFCoreRadioPrv;
    RFCoreRadioPrv.InitAfterRadio = InitAfterRadio;
    RawFrame = RFCoreRadioPrv;
    RawFrameSender = RFCoreRadioPrv;
    RawFrameReceiver = RFCoreRadioPrv;
    RawFrameRSSI = RFCoreRadioPrv;
    RawFrameLQI = RFCoreRadioPrv;
    RawFrameCRC = RFCoreRadioPrv;
    RawFrameTimestamp = RFCoreRadioPrv;
    RawRSSI = RFCoreRadioPrv;
    CoreRadioReceivingNow = RFCoreRadioPrv;
    CoreRadioSimpleAutoACK = RFCoreRadioPrv;
    CoreRadioCRCFiltering = RFCoreRadioPrv;
    RawBLEAdvertiser = RFCoreRadioPrv;
    RawBLEScanner = RFCoreRadioPrv;
    BLEAddressProvider = RFCoreRadioPrv;
    RadioOnLed = RFCoreRadioPrv.RadioOnLed;
}
