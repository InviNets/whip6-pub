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

/**
 * @author Szymon Acedanski
 */
configuration BoardPinsPrv {
}
implementation {
    components CC26xxPinsPub as Pins;

    components HalUART0PinsPub;
    HalUART0PinsPub.TX -> Pins.DIO3;
    HalUART0PinsPub.RX -> Pins.DIO2;

    components HalSPI0PinsPub;
    HalSPI0PinsPub.MISO -> Pins.DIO8;
    HalSPI0PinsPub.MOSI -> Pins.DIO9;
    HalSPI0PinsPub.CLK -> Pins.DIO10;
}
