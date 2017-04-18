/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * Copyright (c) 2017 Uniwersytet Warszawski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE
 * files.
 */

/**
 * @author Szymon Acedanski
 * @author Maciej Debski
 */
configuration BoardPinsPrv {
}
implementation {
    components CC26xxPinsPub as Pins;

    components HalUART0PinsPub;
    HalUART0PinsPub.TX -> Pins.DIO3;
    HalUART0PinsPub.RX -> Pins.DIO2;

/*
    TODO: this are the remaining connected pins, may be useful at some point.

    components HalUART1PinsPub;
    HalUART1PinsPub.TX -> Pins.DIO28;
    HalUART1PinsPub.RX -> Pins.DIO29;
    HalUART1PinsPub.RTS -> Pins.DIO24;
    HalUART1PinsPub.CTS -> Pins.DIO30;

    components HalI2C0PinsPub;
    HalI2C0PinsPub.SCI -> Pins.DIO0;
    HalI2C0PinsPub.SDA -> Pins.DIO1;
*/

}
