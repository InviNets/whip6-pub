/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration CherryMoteHWTestApp {
}
implementation {
    components BoardStartupPub, CherryMoteHWTestPrv;
    CherryMoteHWTestPrv.Boot -> BoardStartupPub;

    components BlockingUART0Pub;
    components new BufferedReaderPub(128) as Reader;
    components new BufferedWriterPub() as Writer;

    Reader.ReadNow -> BlockingUART0Pub.ReadNow;
    Writer.AsyncWrite -> BlockingUART0Pub.AsyncWrite;
    CherryMoteHWTestPrv.BufferedRead -> Reader;
    CherryMoteHWTestPrv.BufferedWrite -> Writer;

    components new TemperatureProviderPub();
    CherryMoteHWTestPrv.ReadTemp -> TemperatureProviderPub;

    components LedsPub;
    CherryMoteHWTestPrv.Led -> LedsPub.Led[0];

    components new PlatformTimerMilliPub();
    CherryMoteHWTestPrv.Timer -> PlatformTimerMilliPub;

    components CoreRawRadioPub;
    CherryMoteHWTestPrv.LowInit -> CoreRawRadioPub;
    CherryMoteHWTestPrv.RawFrame -> CoreRawRadioPub;
    CherryMoteHWTestPrv.LowFrameSender -> CoreRawRadioPub;
    CherryMoteHWTestPrv.LowFrameReceiver -> CoreRawRadioPub;
}
