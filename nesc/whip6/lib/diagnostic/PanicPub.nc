/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Przemyslaw Horban
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
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
