/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration AsyncReadDemoApp {
}

implementation {
    components BoardStartupPub, AsyncReadDemoPrv;
    AsyncReadDemoPrv.Boot -> BoardStartupPub;

    components LedsPub;
    AsyncReadDemoPrv.Green -> LedsPub.Green;
    AsyncReadDemoPrv.Orange -> LedsPub.Orange;
    AsyncReadDemoPrv.Red -> LedsPub.Red;
    AsyncReadDemoPrv.Yellow -> LedsPub.Yellow;

    components new PlatformTimerMilliPub();
    AsyncReadDemoPrv.Timer -> PlatformTimerMilliPub;

    components BlockingUART0Pub;
    AsyncReadDemoPrv.ReadNow -> BlockingUART0Pub;
}
