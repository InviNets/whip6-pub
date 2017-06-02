/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Dawid Łazarczyk
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

configuration CherryMoteHWTestRadioServerApp {
}

implementation {
    components BoardStartupPub, CherryMoteHWTestRadioServerPrv;
    CherryMoteHWTestRadioServerPrv.Boot -> BoardStartupPub;

    components CoreRawRadioPub;
    CherryMoteHWTestRadioServerPrv.LowInit -> CoreRawRadioPub;
    CherryMoteHWTestRadioServerPrv.RawFrame -> CoreRawRadioPub;
    CherryMoteHWTestRadioServerPrv.LowFrameSender -> CoreRawRadioPub;
    CherryMoteHWTestRadioServerPrv.LowFrameReceiver -> CoreRawRadioPub;
}
