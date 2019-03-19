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

#include <CC26xxPinConfig.h>

configuration LedsPub {
    provides interface Led[uint8_t ledNr];
}

implementation {
    components CC26xxPinsPub as Pins;

    // Those are the "virtual leds", pins connected just to supervisor's inputs.

    components new IOPinLedPub(TRUE) as Led0;
    components new HalIOPinPub(OUTPUT_LOW) as Led0Pin;
    Led0Pin.CC26xxPin -> Pins.DIO20;
    Led0.IOPin -> Led0Pin;

    components new IOPinLedPub(TRUE) as Led1;
    components new HalIOPinPub(OUTPUT_LOW) as Led1Pin;
    Led1Pin.CC26xxPin -> Pins.DIO13;
    Led1.IOPin -> Led1Pin;

    components new IOPinLedPub(TRUE) as Led2;
    components new HalIOPinPub(OUTPUT_LOW) as Led2Pin;
    Led2Pin.CC26xxPin -> Pins.DIO14;
    Led2.IOPin -> Led2Pin;

	  components BoardStartupPub;
	  BoardStartupPub.InitSequence[3] -> Led0.Init;
	  BoardStartupPub.InitSequence[3] -> Led1.Init;
	  BoardStartupPub.InitSequence[3] -> Led2.Init;

    components new VirtualLedsPub() as VLeds;
    VLeds.RealLeds[0] -> Led0;
    VLeds.RealLeds[1] -> Led1;
    VLeds.RealLeds[2] -> Led2;

    Led = VLeds.VirtualLeds;
}
