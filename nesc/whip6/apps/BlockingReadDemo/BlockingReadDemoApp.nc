/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration BlockingReadDemoApp {
}

implementation {
    components BoardStartupPub, BlockingReadDemoPrv;
    BlockingReadDemoPrv.Boot -> BoardStartupPub;

    components LedsPub;
    BlockingReadDemoPrv.Green -> LedsPub.Green;
    BlockingReadDemoPrv.Orange -> LedsPub.Orange;
    BlockingReadDemoPrv.Yellow -> LedsPub.Yellow;

    components new PlatformTimerMilliPub();
    BlockingReadDemoPrv.Timer -> PlatformTimerMilliPub;

    components BlockingUART0Pub;
    BlockingReadDemoPrv.BlockingRead -> BlockingUART0Pub;
}
