/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#ifndef PLATFORM_UART_BAUD_RATE
#define PLATFORM_UART_BAUD_RATE 115200
#endif

configuration BlockingUART0Pub {
    provides interface BlockingRead<uint8_t>;
    provides interface ReadNow<uint8_t>;
    provides interface BlockingWrite<uint8_t>;
    provides interface AsyncWrite<uint8_t>;
}

implementation {
    components new HalBlockingUART0Pub(PLATFORM_UART_BAUD_RATE);
    BlockingRead = HalBlockingUART0Pub;
    ReadNow = HalBlockingUART0Pub;
    BlockingWrite = HalBlockingUART0Pub;
    AsyncWrite = HalBlockingUART0Pub;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[0] -> HalBlockingUART0Pub.Init;
}
