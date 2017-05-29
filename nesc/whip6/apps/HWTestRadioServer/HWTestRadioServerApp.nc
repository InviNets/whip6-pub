/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Dawid Łazarczyk
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

configuration HWTestRadioServerApp {
}

implementation {
    components BoardStartupPub, HWTestRadioServerPrv;
    HWTestRadioServerPrv.Boot -> BoardStartupPub;

    components CoreRawRadioPub;
    HWTestRadioServerPrv.LowInit -> CoreRawRadioPub;
    HWTestRadioServerPrv.RawFrame -> CoreRawRadioPub;
    HWTestRadioServerPrv.LowFrameSender -> CoreRawRadioPub;
    HWTestRadioServerPrv.LowFrameReceiver -> CoreRawRadioPub;
}
