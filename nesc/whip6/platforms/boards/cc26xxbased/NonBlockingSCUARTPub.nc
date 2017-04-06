/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2017 University of Warsaw
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */
#ifndef SC_UART_BAUD_RATE
#define SC_UART_BAUD_RATE 230400
#endif

configuration NonBlockingSCUARTPub {
    provides interface NonBlockingWrite<uint8_t>;
} implementation {
    components new PlatformNonBlockingSCUARTPub(SC_UART_BAUD_RATE);
    NonBlockingWrite = PlatformNonBlockingSCUARTPub;

    components BoardStartupPub;
    BoardStartupPub.InitSequence[7] -> PlatformNonBlockingSCUARTPub.Init;
}
