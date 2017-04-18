/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * @author Konrad Iwanicki
 */

configuration CoreMacRadioPub {
    provides interface Init;
    provides interface RawFrame;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface RawFrameRSSI;
    provides interface RawFrameLQI;
    provides interface RawRSSI;
    provides interface XMACControl;

    uses interface AsyncStatsIncrementer<uint8_t> as NumRadioInterruptsStat;
    uses interface AsyncStatsIncrementer<uint8_t> as NumErrorInterruptsStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulRXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulTXStat;
    uses interface StatsIncrementer<uint8_t> as NumLengthErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumCRCErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumTXTimeoutErrorsStat;
}
implementation {
    components CoreRawRadioPub;
    RawFrame = CoreRawRadioPub;
    RawFrameRSSI = CoreRawRadioPub;
    RawFrameLQI = CoreRawRadioPub;
    RawRSSI = CoreRawRadioPub;

    CoreRawRadioPub.NumRadioInterruptsStat = NumRadioInterruptsStat;
    CoreRawRadioPub.NumErrorInterruptsStat = NumErrorInterruptsStat;
    CoreRawRadioPub.NumSuccessfulRXStat = NumSuccessfulRXStat;
    CoreRawRadioPub.NumSuccessfulTXStat = NumSuccessfulTXStat;
    CoreRawRadioPub.NumLengthErrorsStat = NumLengthErrorsStat;
    CoreRawRadioPub.NumCRCErrorsStat = NumCRCErrorsStat;
    CoreRawRadioPub.NumTXTimeoutErrorsStat = NumTXTimeoutErrorsStat;

    components XMACRadioPub;
    Init = XMACRadioPub;
    RawFrameSender = XMACRadioPub;
    RawFrameReceiver = XMACRadioPub;
    XMACControl = XMACRadioPub;
    XMACRadioPub.LowInit -> CoreRawRadioPub;
    XMACRadioPub.RawFrame -> CoreRawRadioPub;
    XMACRadioPub.LowFrameSender -> CoreRawRadioPub;
    XMACRadioPub.LowFrameReceiver -> CoreRawRadioPub;

    components PlatformFrameToXMACFrameAdapterPrv as XMACFrameAdapter;
    components LocalIeee154AddressProviderPub as AddressProvider;
    XMACFrameAdapter.RawFrame -> CoreRawRadioPub;
    XMACFrameAdapter.AddressProvider -> AddressProvider;
    XMACRadioPub.XMACFrame -> XMACFrameAdapter;

    components new PlatformTimer32khzPub() as XMACTimer;
    XMACRadioPub.Timer -> XMACTimer;
}
