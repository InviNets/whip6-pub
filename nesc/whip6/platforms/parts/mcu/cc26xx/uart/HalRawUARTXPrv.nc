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
 * A generic configuration that exposes a raw,
 * but configured UART.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 * @author Szymon Acedanski
 */
generic configuration HalRawUARTXPrv(
        uint32_t uartBase,
        uint32_t baud
)
{
    provides
    {
        interface Init @exactlyonce();
        interface ReadNow<uint8_t> as AsyncRead @atmostonce();
        interface AsyncWrite<uint8_t> @atmostonce();
    }
    uses
    {
        interface CC26xxPin as RXPin @exactlyonce();
        interface CC26xxPin as TXPin @exactlyonce();
        interface ExternalEvent as Interrupt @exactlyonce();
        interface ShareableOnOff as PowerDomain @exactlyonce();
    }
}
implementation
{
    components new HalConfigureUARTPrv(uartBase, baud, FALSE) as CfgPrv;
    components new HalUARTReadNowPrv(uartBase) as UARTReadPrv;
    components new HalUARTAsyncWritePrv(uartBase) as UARTWritePrv;

    PowerDomain = CfgPrv.PowerDomain;
    RXPin = CfgPrv.RXPin;
    TXPin = CfgPrv.TXPin;
    CfgPrv.Interrupt = Interrupt;

    components HalCC26xxSleepPub;
    CfgPrv.ReInitRegisters <- HalCC26xxSleepPub.AtomicAfterDeepSleepInit;

    components new HalAskBeforeSleepPub();
    UARTReadPrv.AskBeforeSleep -> HalAskBeforeSleepPub;
    UARTWritePrv.AskBeforeSleep -> HalAskBeforeSleepPub;

    Init = CfgPrv.Init;
    AsyncRead = UARTReadPrv;
    AsyncWrite = UARTWritePrv;

    Interrupt = UARTReadPrv.Interrupt;
    Interrupt = UARTWritePrv.Interrupt;
}
