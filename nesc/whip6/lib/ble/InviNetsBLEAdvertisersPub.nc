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


generic configuration InviNetsBLEAdvertisersPub(uint32_t baseIntervalMs) {
    provides interface OnOffSwitch @exactlyonce();

    uses interface BLEDeviceNameProvider;
}
implementation {
    components new EddystoneUIDAdvertiserPub(baseIntervalMs) as UIDAdv;

    components InviNetsEddystoneUIDProviderPub as UIDProvider;
    UIDAdv.EddystoneUIDProvider -> UIDProvider;

    components PlatformBLEAddressProviderPub as BLEAddressProvider;
    UIDProvider.BLEAddressProvider -> BLEAddressProvider;

    // Measured with Radius Networks Locate app running on a Sony Xperia Z3
    // Tablet Compact, sender being a CC2650 LaunchPad (our lovely inverted-F
    // antenna), default +5dBm TX power.
    components new ConstEddystoneCalibratedTXPowerProviderPub(-20)
        as TXPowerProvider;
    UIDAdv.EddystoneCalibratedTXPowerProvider -> TXPowerProvider;

    components new EddystoneTLMAdvertiserPub(baseIntervalMs * 10) as TLMAdv;

    components new VDDDividedBy3ProviderPub();
    TLMAdv.VDDDividedBy3 -> VDDDividedBy3ProviderPub;

    components new TemperatureProviderPub();
    TLMAdv.Temperature -> TemperatureProviderPub;

    components new BLEDeviceNameAdvertiserPub(baseIntervalMs * 10) as NameAdv;

    components new DefaultBLEDeviceNameProviderPub("Whip6 Device")
        as NameProvider;
    NameAdv.BLEDeviceNameProvider -> NameProvider;
    BLEDeviceNameProvider = NameProvider.Override;

    OnOffSwitch = UIDAdv;
    OnOffSwitch = TLMAdv;
    OnOffSwitch = NameAdv;
}
