/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


configuration HuntExternalResetPub {
}
implementation {
    components HuntExternalResetPrv;

    components new PlatformTimerMilliPub() as Timer;
    HuntExternalResetPrv.Timer -> Timer;

    components PlatformResetReasonPub;
    HuntExternalResetPrv.ResetReason -> PlatformResetReasonPub;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[3] -> HuntExternalResetPrv;
}
