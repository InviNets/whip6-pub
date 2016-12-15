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
