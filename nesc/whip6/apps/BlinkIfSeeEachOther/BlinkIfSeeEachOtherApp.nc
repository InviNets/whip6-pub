/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

configuration BlinkIfSeeEachOtherApp {
}

implementation {
    components BoardStartupPub, BlinkIfSeeEachOtherPrv;
    BlinkIfSeeEachOtherPrv.Boot -> BoardStartupPub;

    components LedsPub;
    BlinkIfSeeEachOtherPrv.Led0 -> LedsPub.Led[0];
    BlinkIfSeeEachOtherPrv.Led1 -> LedsPub.Led[1];

    components new PlatformTimerMilliPub() as Timer;
    BlinkIfSeeEachOtherPrv.Timer -> Timer;

    components CoreRawRadioPub;
    BlinkIfSeeEachOtherPrv.LowInit -> CoreRawRadioPub;
    BlinkIfSeeEachOtherPrv.RawFrame -> CoreRawRadioPub;
    BlinkIfSeeEachOtherPrv.LowFrameSender -> CoreRawRadioPub;
    BlinkIfSeeEachOtherPrv.LowFrameReceiver -> CoreRawRadioPub;
}
