/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */



/**
 * A provider of BufferedRead and BufferedWrite
 * interfaces for UART0.
 *
 * @author Konrad Iwanicki
 * @author Szymon Acedanski
 */
configuration BufferedUART0ProviderPub
{
    provides
    {
        interface BufferedRead;
        interface BufferedWrite;
    }
}
implementation
{
    components BlockingUART0Pub;
    components new DummyBufferedReaderPub() as BufReadPrv;
    components new BlockingWriteBufferedWriterPub() as BufWritePrv;

    BufferedRead =  BufReadPrv.BufferedRead;
    BufferedWrite =  BufWritePrv.BufferedWrite;

    BufWritePrv.BlockingWrite -> BlockingUART0Pub;
}
