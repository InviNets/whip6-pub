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


#ifndef PLATFORM_UART_BAUD_RATE
#define PLATFORM_UART_BAUD_RATE 115200
#endif

configuration BlockingUART0Pub {
    provides interface BlockingWrite<uint8_t>;
}
implementation {
    components new HalBlockingUART0Pub(PLATFORM_UART_BAUD_RATE);
    BlockingWrite = HalBlockingUART0Pub;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[0] -> HalBlockingUART0Pub.Init;
}
