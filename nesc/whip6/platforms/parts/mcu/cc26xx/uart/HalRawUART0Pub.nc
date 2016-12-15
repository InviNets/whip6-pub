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


#include "hw_memmap.h"

/**
 * Configuration for UART 0.
 *
 * @author Konrad Iwanicki
 * @author Przemyslaw Horban
 * @author Michal Marschall <m.marschall@invinets.com>
 * @author Szymon Acedanski
 */
generic configuration HalRawUART0Pub(
        uint32_t baud
)
{
    provides
    {
        interface Init @exactlyonce();
        interface ReadNow<uint8_t> as AsyncRead;
        interface AsyncWrite<uint8_t>;
    }
}
implementation {
    components new HalRawUARTXPrv(UART0_BASE, baud) as GenericUartPrv;
    components HplUARTInterruptsPub as Ints;
    components CC26xxPowerDomainsPub as PowerDomains;
    components HalUART0PinsPub as Pins;

    Init = GenericUartPrv.Init;
    AsyncRead = GenericUartPrv.AsyncRead;
    AsyncWrite = GenericUartPrv.AsyncWrite;

    GenericUartPrv.Interrupt -> Ints.UART0Interrupt;
    GenericUartPrv.PowerDomain -> PowerDomains.SerialDomain;
    GenericUartPrv.RXPin -> Pins.PRX;
    GenericUartPrv.TXPin -> Pins.PTX;
}

