/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 * @author Konrad Iwanicki
 * @author Michal Marschall <m.marschall@invinets.com>
 *
 * Apart from providing radio functionality, this module initializes random seed with radio
 * noise on radio initialization.
 */

#include "cipher_aes128.h"

configuration CoreRawRadioPub {
    provides interface Init;
    provides interface RawFrame;
    provides interface RawFrameSender;
    provides interface RawFrameReceiver;
    provides interface RawFrameRSSI;
    provides interface RawFrameLQI;
    provides interface RawFrameCRC;
    provides interface RawRSSI;
    provides interface CoreRadioReceivingNow;
    provides interface CoreRadioSimpleAutoACK;
    provides interface CoreRadioCRCFiltering;

    uses interface AsyncStatsIncrementer<uint8_t> as NumRadioInterruptsStat;
    uses interface AsyncStatsIncrementer<uint8_t> as NumErrorInterruptsStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulRXStat;
    uses interface StatsIncrementer<uint8_t> as NumSuccessfulTXStat;
    uses interface StatsIncrementer<uint8_t> as NumLengthErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumCRCErrorsStat;
    uses interface StatsIncrementer<uint8_t> as NumTXTimeoutErrorsStat;
}
implementation {
    components HalRadioPub;
    RawFrame = HalRadioPub;
    RawFrameRSSI = HalRadioPub;
    RawFrameLQI = HalRadioPub;
    RawFrameCRC = HalRadioPub;
    RawRSSI = HalRadioPub;
    CoreRadioReceivingNow = HalRadioPub;
    CoreRadioSimpleAutoACK = HalRadioPub;
    CoreRadioCRCFiltering = HalRadioPub;

    HalRadioPub.NumRadioInterruptsStat = NumRadioInterruptsStat;
    HalRadioPub.NumErrorInterruptsStat = NumErrorInterruptsStat;
    HalRadioPub.NumSuccessfulRXStat = NumSuccessfulRXStat;
    HalRadioPub.NumSuccessfulTXStat = NumSuccessfulTXStat;
    HalRadioPub.NumLengthErrorsStat = NumLengthErrorsStat;
    HalRadioPub.NumCRCErrorsStat = NumCRCErrorsStat;
    HalRadioPub.NumTXTimeoutErrorsStat = NumTXTimeoutErrorsStat;

    Init = HalRadioPub;
    RawFrameSender = HalRadioPub;
    RawFrameReceiver = HalRadioPub;
}
