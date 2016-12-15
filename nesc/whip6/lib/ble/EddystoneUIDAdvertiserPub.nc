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


generic configuration EddystoneUIDAdvertiserPub(uint32_t intervalMs) {
    provides interface OnOffSwitch;

    uses interface EddystoneUIDProvider;
    uses interface EddystoneCalibratedTXPowerProvider;
}
implementation {
    components new EddystoneUIDAdvertiserPrv(intervalMs) as Prv;

    components new PlatformBLEAdvertiserPub();
    Prv.RawBLEAdvertiser -> PlatformBLEAdvertiserPub;

    components new PlatformTimerMilliPub() as Timer;
    Prv.Timer -> Timer;

    components PlatformRandomPub as Random;
    Prv.Random -> Random;

    OnOffSwitch = Prv;
    EddystoneUIDProvider = Prv;
    EddystoneCalibratedTXPowerProvider = Prv;
}
