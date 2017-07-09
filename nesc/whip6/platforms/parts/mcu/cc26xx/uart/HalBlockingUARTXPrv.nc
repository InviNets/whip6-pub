/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */




/**
 * A generic configuration that exposes an UART in blocking mode.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 * @author Szymon Acedanski
 */
generic configuration HalBlockingUARTXPrv(
        uint32_t uartBase,
        uint32_t baud
)
{
    provides
    {
        interface Init @exactlyonce();
        interface BlockingRead<uint8_t>;
        interface ReadNow<uint8_t>;
        interface BlockingWrite<uint8_t>;
        interface AsyncWrite<uint8_t>;
    }

    uses
    {
        interface CC26xxPin as RXPin;
        interface CC26xxPin as TXPin;
        interface CC26xxPin as RTSPin;
        interface CC26xxPin as CTSPin;
        interface ShareableOnOff as PowerDomain;
        interface ExternalEvent as Interrupt @exactlyonce();
    }
}
implementation
{
    // Can't use FIFO, because of no TX-complete interrupt,
    // see HalUARTBlockingWritePrv.nc.
    components new HalConfigureUARTPrv(uartBase, baud, FALSE) as CfgPrv;

    components new HalUARTBlockingReadPrv(uartBase) as UARTReadPrv;
    components new HalUARTReadNowPrv(uartBase) as UARTReadNowPrv;
    components new HalUARTBlockingWritePrv(uartBase) as UARTWritePrv;
    components new HalUARTAsyncWritePrv(uartBase) as UARTAsyncWritePrv;

    CfgPrv.PowerDomain = PowerDomain;
    CfgPrv.RXPin = RXPin;
    CfgPrv.TXPin = TXPin;
    CfgPrv.RTSPin = RTSPin;
    CfgPrv.CTSPin = CTSPin;
    CfgPrv.Interrupt = Interrupt;

    components HalCC26xxSleepPub;
    CfgPrv.ReInitRegisters <- HalCC26xxSleepPub.AtomicAfterDeepSleepInit;

    components new HalAskBeforeSleepPub();
    UARTReadNowPrv.AskBeforeSleep -> HalAskBeforeSleepPub;
    UARTWritePrv.AskBeforeSleep -> HalAskBeforeSleepPub;
    UARTAsyncWritePrv.AskBeforeSleep -> HalAskBeforeSleepPub;

    Init = CfgPrv.Init;
    BlockingRead = UARTReadPrv;
    ReadNow = UARTReadNowPrv;
    BlockingWrite = UARTWritePrv;
    AsyncWrite = UARTAsyncWritePrv;

    Interrupt = UARTReadNowPrv.Interrupt;
    Interrupt = UARTWritePrv.Interrupt;
    Interrupt = UARTAsyncWritePrv.Interrupt;
}
