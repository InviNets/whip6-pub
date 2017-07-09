/**
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 */

configuration UARTFlowControlTestApp {
}

implementation {
    components BoardStartupPub, UARTFlowControlTestPrv;
    UARTFlowControlTestPrv.Boot -> BoardStartupPub;

    components new PlatformTimerMilliPub() as Timer1;
    components new PlatformTimerMilliPub() as Timer2;
    UARTFlowControlTestPrv.Timer1 -> Timer1;
    UARTFlowControlTestPrv.Timer2 -> Timer2;

    components SleepDisablePub;
    UARTFlowControlTestPrv.OnOffSwitch -> SleepDisablePub;

    components BlockingUART0Pub;
    components new BufferedReaderPub(128) as Reader;
    components new BufferedWriterPub() as Writer;
    Reader.ReadNow -> BlockingUART0Pub.ReadNow;
    Writer.AsyncWrite -> BlockingUART0Pub.AsyncWrite;
    UARTFlowControlTestPrv.BufferedRead -> Reader;
    UARTFlowControlTestPrv.BufferedWrite -> Writer;
}
