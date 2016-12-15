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

generic configuration PlatformIOChannelPrv(int num, int channel) {
    provides interface IOVRead;
    provides interface IOVWrite;
}
implementation {
    components PlatformIOMuxPrv;
    IOVRead = PlatformIOMuxPrv.IOVRead[num];
    IOVWrite = PlatformIOMuxPrv.IOVWrite[num];

    components new IOChannelConfigPub(channel) as RChannelConfig;
    PlatformIOMuxPrv.ReadConfig[num] <- RChannelConfig;
    components new IOChannelConfigPub(channel) as WChannelConfig;
    PlatformIOMuxPrv.WriteConfig[num] <- WChannelConfig;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[0] -> RChannelConfig;
    BoardStartupPub.InitSequence[0] -> WChannelConfig;
}
