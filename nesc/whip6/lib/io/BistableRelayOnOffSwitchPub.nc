/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski <accek@mimuw.edu.pl>
 */

generic configuration BistableRelayOnOffSwitchPub(bool pinHighMeansOn,
        uint32_t impulseLengthMs) {
    uses interface IOPin as SetPin;
    uses interface IOPin as ResetPin;

    provides interface Init @exactlyonce();
    provides interface OnOffSwitch as OnOff;
}
implementation{
    components new PinOnOffSwitchPub(pinHighMeansOn) as SetSwitch;
    SetPin = SetSwitch.Pin;
    Init = SetSwitch.Init;
    components new PinOnOffSwitchPub(pinHighMeansOn) as ResetSwitch;
    ResetPin = ResetSwitch.Pin;
    Init = ResetSwitch.Init;
    components new PlatformTimerMilliPub() as Timer;
    components new BistableRelayOnOffSwitchPrv(impulseLengthMs) as Impl;
    Impl.SetSwitch -> SetSwitch;
    Impl.ResetSwitch -> ResetSwitch;
    Impl.Timer -> Timer;
    OnOff = Impl;
}
