/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Konrad Iwanicki
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include "hw_memmap.h"

/**
 * Configuration for UART 0.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */
generic configuration HalBlockingUART0Pub(
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
}
implementation {
    components new HalBlockingUARTXPrv(UART0_BASE, baud) as GenericUartPrv;
    components HplUARTInterruptsPub as Ints;
    components HalUART0PinsPub as Pins;
    components CC26xxPowerDomainsPub as PowerDomains;

    Init = GenericUartPrv.Init;
    BlockingRead = GenericUartPrv.BlockingRead;
    ReadNow = GenericUartPrv.ReadNow;
    BlockingWrite = GenericUartPrv.BlockingWrite;
    AsyncWrite = GenericUartPrv.AsyncWrite;

    GenericUartPrv.Interrupt -> Ints.UART0Interrupt;
    GenericUartPrv.PowerDomain -> PowerDomains.SerialDomain;
    GenericUartPrv.RXPin -> Pins.PRX;
    GenericUartPrv.TXPin -> Pins.PTX;
    GenericUartPrv.RTSPin -> Pins.PRTS;
    GenericUartPrv.CTSPin -> Pins.PCTS;
}
