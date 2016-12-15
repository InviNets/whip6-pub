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

configuration PanicPub {
    uses interface PanicHook;
}
implementation {
    components PanicPrv;

    components BusyWaitProviderPub;
    PanicPrv.BusyWait -> BusyWaitProviderPub;

    components LedsPub;
    PanicPrv.Led -> LedsPub.Led;

    components SoftwareResetPub;
    PanicPrv.Reset -> SoftwareResetPub;

    PanicHook = PanicPrv.PanicHook;
}
