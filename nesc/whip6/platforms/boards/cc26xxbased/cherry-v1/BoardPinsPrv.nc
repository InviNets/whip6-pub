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
    HalUART0PinsPub.TX -> Pins.DIO28;
    HalUART0PinsPub.RX -> Pins.DIO29;
    HalUART0PinsPub.RTS -> Pins.DIO24;
    HalUART0PinsPub.CTS -> Pins.DIO30;

    components HalI2CPinsPub;
    HalI2CPinsPub.SCL -> Pins.DIO0;
    HalI2CPinsPub.SDA -> Pins.DIO1;
}
