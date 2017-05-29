/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration HWTestApp {
}
implementation {
    components BoardStartupPub, HWTestPrv;
    HWTestPrv.Boot -> BoardStartupPub;

    components BlockingUART0Pub;
    components new BufferedReaderPub(128) as Reader;
    components new BufferedWriterPub() as Writer;

    Reader.ReadNow -> BlockingUART0Pub.ReadNow;
    Writer.AsyncWrite -> BlockingUART0Pub.AsyncWrite;
    HWTestPrv.BufferedRead -> Reader;
    HWTestPrv.BufferedWrite -> Writer;

    components new TemperatureProviderPub();
    HWTestPrv.ReadTemp -> TemperatureProviderPub;

    components LedsPub;
    HWTestPrv.Led -> LedsPub.Led[0];

    components new PlatformTimerMilliPub();
    HWTestPrv.Timer -> PlatformTimerMilliPub;

    components CoreRawRadioPub;
    HWTestPrv.LowInit -> CoreRawRadioPub;
    HWTestPrv.RawFrame -> CoreRawRadioPub;
    HWTestPrv.LowFrameSender -> CoreRawRadioPub;
    HWTestPrv.LowFrameReceiver -> CoreRawRadioPub;
}
