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
