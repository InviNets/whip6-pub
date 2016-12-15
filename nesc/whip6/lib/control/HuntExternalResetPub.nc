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
