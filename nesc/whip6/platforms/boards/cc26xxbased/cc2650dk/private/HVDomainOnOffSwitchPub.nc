/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


#include <CC26xxPinConfig.h>

configuration HVDomainOnOffSwitchPub {
    provides interface OnOffSwitch;
}
implementation {
    components new PinOnOffSwitchPub(TRUE);

    components BoardStartupPub;
    BoardStartupPub.InitSequence[0] -> PinOnOffSwitchPub;

    components new HalIOPinPub(OUTPUT_LOW) as HVEnPin;
    components CC26xxPinsPub;
    HVEnPin.CC26xxPin -> CC26xxPinsPub.DIO13;
    PinOnOffSwitchPub.Pin -> HVEnPin;

    OnOffSwitch = PinOnOffSwitchPub;
}
