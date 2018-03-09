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
    HalUART0PinsPub.CTS -> Pins.DIO9;
    HalUART0PinsPub.RTS -> Pins.DIO8;

    components HalI2CPinsPub;
    HalI2CPinsPub.SCL -> Pins.DIO19;
    HalI2CPinsPub.SDA -> Pins.DIO18;

}
