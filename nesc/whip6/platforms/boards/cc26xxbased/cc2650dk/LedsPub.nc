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

#include <CC26xxPinConfig.h>

configuration LedsPub {
    provides interface Led[uint8_t ledNr];
    
	provides interface Led as Red;
	provides interface Led as Yellow;
	provides interface Led as Green;
	provides interface Led as Orange;
}

implementation {
    components CC26xxPinsPub as Pins;

    components new IOPinLedPub(TRUE) as Led1;
    components new HalIOPinPub(OUTPUT_LOW) as Led1Pin;
    Led1Pin.CC26xxPin -> Pins.DIO25;
    Led1.IOPin -> Led1Pin;

    components new IOPinLedPub(TRUE) as Led2;
    components new HalIOPinPub(OUTPUT_LOW) as Led2Pin;
    Led2Pin.CC26xxPin -> Pins.DIO27;
    Led2.IOPin -> Led2Pin;

    components new IOPinLedPub(TRUE) as Led3;
    components new HalIOPinPub(OUTPUT_LOW) as Led3Pin;
    Led3Pin.CC26xxPin -> Pins.DIO7;
    Led3.IOPin -> Led3Pin;

    components new IOPinLedPub(TRUE) as Led4;
    components new HalIOPinPub(OUTPUT_LOW) as Led4Pin;
    Led4Pin.CC26xxPin -> Pins.DIO6;
    Led4.IOPin -> Led4Pin;

	components BoardStartupPub;
	BoardStartupPub.InitSequence[3] -> Led1.Init;
	BoardStartupPub.InitSequence[3] -> Led2.Init;
	BoardStartupPub.InitSequence[3] -> Led3.Init;
	BoardStartupPub.InitSequence[3] -> Led4.Init;

    // OK, so many components assume that there exists a red
    // LED that we wire the yellow led, too. Actually, three
    // LEDs on the board: red, yellow and orange, actually
    // look almost the same. :(

    Red = Led1;
    Yellow = Led2;
    Green = Led3;
    Orange = Led4;

    components new VirtualLedsPub() as VLeds;
    VLeds.RealLeds[0] -> Led1;
    VLeds.RealLeds[1] -> Led2;
    VLeds.RealLeds[2] -> Led3;
    VLeds.RealLeds[3] -> Led4;

    Led = VLeds.VirtualLeds;
}
