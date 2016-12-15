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

configuration ButtonsPub {
    provides interface ButtonPress as Buttons[uint8_t num];
    provides interface ButtonPress as Select;
    provides interface ButtonPress as Left;
    provides interface ButtonPress as Right;
    provides interface ButtonPress as Up;
    provides interface ButtonPress as Down;
}
implementation {
    components HalGPIOInterruptsPub as Ints;
    components CC26xxPinsPub as Pins;

    components new HalIOPinForButtonPub(FALSE) as BP1;
    BP1.CC26xxPin -> Pins.DIO11;
    BP1.GPIOEventConfig -> Ints.GPIOEventConfig[11];
    components new BothEdgesDebouncerPub(200) as BTN1;
    components new PlatformTimerMilliPub() as T1;
    BTN1.ExternalEvent -> Ints.ExternalEvent[11];
    BTN1.Timer -> T1;
    BTN1.HalButton -> BP1;
    Select = BTN1;
    Buttons[0] = BTN1;

    components new HalIOPinForButtonPub(FALSE) as BP2;
    BP2.CC26xxPin -> Pins.DIO15;
    BP2.GPIOEventConfig -> Ints.GPIOEventConfig[15];
    components new BothEdgesDebouncerPub(200) as BTN2;
    components new PlatformTimerMilliPub() as T2;
    BTN2.ExternalEvent -> Ints.ExternalEvent[15];
    BTN2.Timer -> T2;
    BTN2.HalButton -> BP2;
    Left = BTN2;
    Buttons[1] = BTN2;

    components new HalIOPinForButtonPub(FALSE) as BP3;
    BP3.CC26xxPin -> Pins.DIO18;
    BP3.GPIOEventConfig -> Ints.GPIOEventConfig[18];
    components new BothEdgesDebouncerPub(200) as BTN3;
    components new PlatformTimerMilliPub() as T3;
    BTN3.ExternalEvent -> Ints.ExternalEvent[18];
    BTN3.Timer -> T3;
    BTN3.HalButton -> BP3;
    Right = BTN3;
    Buttons[2] = BTN3;

    components new HalIOPinForButtonPub(FALSE) as BP4;
    BP4.CC26xxPin -> Pins.DIO19;
    BP4.GPIOEventConfig -> Ints.GPIOEventConfig[19];
    components new BothEdgesDebouncerPub(200) as BTN4;
    components new PlatformTimerMilliPub() as T4;
    BTN4.ExternalEvent -> Ints.ExternalEvent[19];
    BTN4.Timer -> T4;
    BTN4.HalButton -> BP4;
    Up = BTN4;
    Buttons[3] = BTN4;

    components new HalIOPinForButtonPub(FALSE) as BP5;
    BP5.CC26xxPin -> Pins.DIO12;
    BP5.GPIOEventConfig -> Ints.GPIOEventConfig[12];
    components new BothEdgesDebouncerPub(200) as BTN5;
    components new PlatformTimerMilliPub() as T5;
    BTN5.ExternalEvent -> Ints.ExternalEvent[12];
    BTN5.Timer -> T5;
    BTN5.HalButton -> BP5;
    Down = BTN5;
    Buttons[4] = BTN5;
}
