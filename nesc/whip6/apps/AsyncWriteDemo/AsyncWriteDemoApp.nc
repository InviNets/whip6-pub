/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration AsyncWriteDemoApp {
}

implementation {
    components BoardStartupPub, AsyncWriteDemoPrv;
    AsyncWriteDemoPrv.Boot -> BoardStartupPub;

    components LedsPub;
    AsyncWriteDemoPrv.Yellow -> LedsPub.Yellow;
    AsyncWriteDemoPrv.Green -> LedsPub.Green;
    AsyncWriteDemoPrv.Orange -> LedsPub.Orange;
    AsyncWriteDemoPrv.Red -> LedsPub.Red;

    components new PlatformTimerMilliPub() as Timer1;
    components new PlatformTimerMilliPub() as Timer2;
    AsyncWriteDemoPrv.Timer1 -> Timer1;
    AsyncWriteDemoPrv.Timer2 -> Timer2;

    components BlockingUART0Pub;
    AsyncWriteDemoPrv.AsyncWrite -> BlockingUART0Pub;
}
