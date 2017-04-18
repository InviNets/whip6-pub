/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Szymon Acedanski
 */

configuration PlatformBLEInitPrv {
}

implementation {
    components BoardStartupPub;
    BoardStartupPub.InitSequence[3] -> Hal.Init;

    components HalRadioPub as Hal;
    components PlatformBLEAddressProviderPub as Address;
    Hal.BLEAddressProvider -> Address.BLEAddressProvider;
}
